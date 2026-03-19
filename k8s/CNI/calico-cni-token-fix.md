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
| initContainer (calico/node 이미지) | initContainer에서 영구 토큰으로 kubeconfig 작성 | X | VM resume 시 Pod 재시작 안 되므로 initContainer 실행 안 됨 |
| Sidecar (cni-token-guardian) | 5분마다 영구 토큰으로 kubeconfig 덮어씀 | △ | 동작하지만 노드당 추가 컨테이너 리소스 소비 |
| **calico-node SA 영구 토큰** | calico-node 자체 SA 토큰을 영구로 변경 | **O** | 근본 원인 해결, 추가 리소스 없음 |

### 참고: calico/cni vs calico/node 이미지

| 이미지 | 기반 | /bin/sh | 용도 |
|--------|------|:-------:|------|
| `calico/cni` | scratch | 없음 | CNI 바이너리만 포함, shell 실행 불가 |
| `calico/node` | busybox | 있음 | calico-node 데몬 + busybox 유틸리티 |

initContainer에서 shell 스크립트 실행 시 반드시 `calico/node` 이미지를 사용해야 함.

## 적용할 방안: calico-node SA 영구 토큰

### 원리

```
VM resume 후:
    calico-node의 SA 토큰 = kubernetes.io/service-account-token (만료 없음)
    → TokenRequest API 호출 성공
    → 24h CNI 토큰 즉시 갱신
    → CNI 정상 동작
```

projected SA 토큰(1시간 만료) 대신 Static Secret(만료 없음)을 사용하여, VM이 며칠간 suspend 되었다가 resume 되어도 calico-node가 즉시 API 서버와 통신 가능.

### 변경 사항 (`calico-quay-v3.31.2.yaml`)

1. **calico-node SA용 Static Secret 추가**
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

2. **DaemonSet pod spec 변경**
   - `automountServiceAccountToken: false` 추가
   - `calico-node-token` volume 추가
   - 모든 initContainer(3개) + container(1개)에 volumeMount 추가:
     ```yaml
     - name: calico-node-token
       mountPath: /var/run/secrets/kubernetes.io/serviceaccount
       readOnly: true
     ```

3. **기존 sidecar/initContainer (refresh-cni-token) 제거**
   - calico-node 자체 갱신이 동작하므로 불필요

4. **calico-cni-plugin Static Secret은 유지**
   - 초기 부팅 시 calico-node가 아직 시작 전인 짧은 구간의 안전망

### 장단점

**장점:**
- 추가 리소스 없음 (sidecar/initContainer 불필요)
- 복구 지연 0초 (VM resume 후 즉시 동작)
- 근본 원인 해결 (calico-node 인증 보장)

**단점:**
- YAML 변경량 많음 (initContainer 3개 + container 1개에 volumeMount 추가)
- calico 업그레이드 시 새 initContainer가 추가되면 volumeMount도 함께 추가 필요
- calico-node SA의 영구 토큰은 광범위 권한 보유 (교육/랩 환경에서는 허용 가능)

## 적용 대상

- 파일: `calico-quay-v3.31.2.yaml`
- 사용처: https://github.com/sysnet4admin/SSF/blob/main/Module-1/vanilla-k8s/controlplane_node.sh
- 배포 방식: `kubectl apply -f $CNI_ADDR/calico-quay-v3.31.2.yaml`

## 검증 항목

1. 전체 노드 Ready 확인
2. calico-node 전 노드 Running (READY 2/2 아닌 1/1 유지)
3. busybox 배포 및 DNS 확인
4. calico-node SA 토큰에 `exp` 필드 없음 확인
5. CNI kubeconfig 토큰이 정상 갱신되는지 확인
