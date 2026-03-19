# Calico CNI Token Expiration Fix

## 문제

VM을 한동안 사용하지 않다가 다시 켜면(호스트 노트북 닫기 → 며칠 후 열기) calico-node가 정상 동작하지 않아 새 Pod 배포가 불가능함.

### 근본 원인

```
호스트 suspend → 며칠 경과 → 호스트 resume
    → VirtualBox VM 시간만 점프 (VM reboot 아님, Pod 재시작 안 됨)
    → calico-node의 projected SA 토큰 (3607초=1시간) 만료
    → calico-node가 TokenRequest API 호출 불가 (401)
    → /etc/cni/net.d/calico-kubeconfig의 24h CNI 토큰 갱신 실패
    → CNI 플러그인 인증 실패 → 새 Pod 배포 불가
```

- calico-node의 CNI 토큰 유효기간(24h)은 `token_watch.go`에 하드코딩 (`defaultCNITokenValiditySeconds = 86400`)
- 외부에서 변경 가능한 설정 없음
- 정상 시 calico-node가 ~6시간마다 자동 갱신하지만, 자체 SA 토큰이 만료되면 갱신 불가

### 참고 소스

- https://raw.githubusercontent.com/projectcalico/calico/v3.31.2/node/pkg/cni/token_watch.go
- https://github.com/projectcalico/calico/issues/8368

## 검토한 방안

| 방안 | 설명 | 판정 | 사유 |
|------|------|:----:|------|
| `CNI_TOKEN_REFRESH_INTERVAL` 단축 | 갱신 주기를 줄임 | X | 기본값이 이미 5분. 갱신 주기가 아닌 인증 실패가 문제 |
| Static Secret + `chattr +i` | 영구 토큰 + 파일 불변 | X | calico/node 이미지에 chattr 없음, 로그 스팸 발생 |
| `bitnami/kubectl` initContainer | 외부 이미지로 `kubectl create token --duration=87600h` | X | 외부 이미지 의존, Pod 재시작 시에만 동작 (VM resume에 무효) |
| initContainer (calico/cni) | initContainer에서 영구 토큰으로 kubeconfig 작성 | X | calico/cni는 scratch 기반으로 `/bin/sh` 없어 실행 불가 |
| initContainer (calico/node) | 위와 동일하되 calico/node 이미지 사용 | X | shell은 있지만 VM resume 시 Pod 재시작 안 되므로 실행 안 됨 |
| Sidecar (cni-token-guardian) | 5분마다 영구 토큰으로 kubeconfig 덮어씀 | △ | 동작하지만 노드당 추가 컨테이너 리소스 소비 |
| **calico-node SA 영구 토큰** | calico-node 자체 SA 토큰을 영구로 변경 | **O** | 근본 원인 해결, 추가 리소스 없음 |

### 참고: calico/cni vs calico/node 이미지

| 이미지 | 기반 | /bin/sh | 용도 |
|--------|------|:-------:|------|
| `calico/cni` | scratch | 없음 | CNI 바이너리만 포함, shell 실행 불가 |
| `calico/node` | busybox | 있음 (단, chmod 등 일부 명령 없음) | calico-node 데몬 + busybox 유틸리티 |

### Sidecar vs SA 영구 토큰 비교

| 항목 | Sidecar | SA 영구 토큰 |
|------|:---:|:---:|
| 복구 지연 | 최대 5분 | 즉시 (0초) |
| 원리 | 증상 우회 (kubeconfig 직접 덮어씀) | 근본 원인 해결 (calico-node 인증 보장) |
| YAML 변경량 | 적음 (container 1개 + volume 1개) | 많음 (Secret + automount + volumeMount 4개소) |
| 추가 리소스 | 노드당 ~10m CPU, 16Mi 메모리 | 없음 |
| calico 업그레이드 시 | 수정 없음 | initContainer 추가 시 volumeMount도 추가 필요 |
| calico-node 내부 갱신 의존 | 독립적 | 의존함 (갱신 고루틴 자체가 죽으면 안 됨) |
| 보안 | calico-cni-plugin SA 영구 토큰 (제한 권한) | calico-node SA 영구 토큰 (광범위 권한) |

**결정: SA 영구 토큰** - 리소스가 제한적인 랩 환경에서 추가 컨테이너 비용이 문제됨.

## 적용한 방안: calico-node SA 영구 토큰

### 원리

```
VM resume 후:
    calico-node의 SA 토큰 = kubernetes.io/service-account-token (만료 없음)
    → TokenRequest API 호출 성공
    → 24h CNI 토큰 즉시 갱신
    → CNI 정상 동작
```

projected SA 토큰(1시간 만료) 대신 Static Secret(만료 없음)을 사용하여, VM이 며칠간 suspend 되었다가 resume 되어도 calico-node가 즉시 API 서버와 통신 가능.

### 원본 YAML 대비 변경 사항 (`calico-quay-v3.31.2.yaml`)

**1. calico-node SA용 Static Secret 추가** (ServiceAccount 정의 뒤)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: calico-node-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: calico-node
type: kubernetes.io/service-account-token
```

**2. DaemonSet pod spec에 `automountServiceAccountToken: false` 추가**
```yaml
serviceAccountName: calico-node
automountServiceAccountToken: false   # 추가
```

**3. 모든 initContainer(3개) + container(1개)에 volumeMount 추가**

대상: `upgrade-ipam`, `install-cni`, `ebpf-bootstrap`, `calico-node`
```yaml
volumeMounts:
  # ... 기존 마운트 유지 ...
  - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
    name: calico-node-token
    readOnly: true
```

**4. volumes에 calico-node-token 추가**
```yaml
volumes:
  # ... 기존 볼륨 유지 ...
  - name: calico-node-token
    secret:
      secretName: calico-node-token
```

sidecar/initContainer 추가 없음. 원본 calico YAML의 컨테이너 구성을 변경하지 않음.

### 커밋 이력

| 커밋 | 내용 | 비고 |
|------|------|------|
| `3a8f538` | calico-cni-plugin-token Secret + refresh-cni-token initContainer 추가 | 중간 시도 |
| `4c6f17e` | initContainer 이미지 calico/cni → calico/node (shell 필요) | 중간 수정 |
| `7f90679` | initContainer에서 chmod 제거 (busybox에 없음) | 중간 수정 |
| `61768e2` | initContainer → sidecar(cni-token-guardian)로 교체 | 중간 시도 |
| **`775f6c5`** | **sidecar 제거, calico-node SA 영구 토큰으로 최종 교체** | **최종** |

## 적용 대상

- 파일: `calico-quay-v3.31.2.yaml`
- 사용처: https://github.com/sysnet4admin/SSF/blob/main/Module-1/vanilla-k8s/controlplane_node.sh
- 배포 방식: `kubectl apply -f $CNI_ADDR/calico-quay-v3.31.2.yaml`

## 검증 결과 (2026-03-19)

SSF vanilla-k8s (`vagrant up`) 배포 후 확인:

| 항목 | 결과 |
|------|------|
| 전체 노드 Ready | CP + w1 + w2 + w3 (4/4) |
| calico-node 전 노드 Running | 4/4 (READY 1/1, sidecar 없음) |
| **calico-node SA 토큰** | **`exp` 필드 없음 → 만료 없음 (영구)** |
| CNI kubeconfig 토큰 | calico-node가 정상 갱신한 24h 토큰 (calico-cni-plugin SA) |
| busybox 배포 | 성공 (172.16.103.129, w2-k8s) |
| DNS | `kubernetes.default.svc.cluster.local` → `10.96.0.1` 정상 |

## 미검증 (주말 테스트 예정)

- [ ] 호스트 suspend → 며칠 경과 → resume 후 새 Pod 배포 정상 여부
- [ ] resume 후 calico-node가 CNI 토큰을 즉시 갱신하는지 확인
- [ ] resume 후 calico-node 로그에 401/403 에러 없는지 확인
