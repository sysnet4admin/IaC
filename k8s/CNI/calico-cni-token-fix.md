# Calico CNI Token Expiration Fix

## 왜 이 수정이 필요한가

호스트 노트북을 닫고 며칠 후 다시 열면, VirtualBox VM은 reboot 없이 시간만 점프한다.
이때 calico-node Pod도 재시작 없이 그대로 resume 되는데, calico-node가 API 서버와 통신할 때 사용하는 projected SA 토큰(유효기간 3607초=1시간)이 이미 만료된 상태다.

```
호스트 suspend → 며칠 경과 → resume
    → calico-node의 projected SA 토큰 만료 (3607초)
    → TokenRequest API 호출 실패 (401)
    → CNI kubeconfig의 24h 토큰 갱신 불가
    → 새 Pod 배포 불가
```

calico-node는 정상 시 ~6시간마다 CNI 토큰을 갱신하지만, 자체 SA 토큰이 만료되면 갱신 자체가 불가능하다.
CNI 토큰 유효기간(24h)은 `token_watch.go`에 하드코딩(`defaultCNITokenValiditySeconds = 86400`)되어 있고 외부에서 변경할 수 없다.

참고:
- https://raw.githubusercontent.com/projectcalico/calico/v3.31.2/node/pkg/cni/token_watch.go
- https://github.com/projectcalico/calico/issues/8368

## 왜 이 방식으로 구현했는가

문제의 근본 원인은 calico-node의 **자체 SA 토큰 만료**이다. CNI 토큰이 아니라 calico-node가 API 서버에 인증하는 토큰이 문제다.

`kubernetes.io/service-account-token` 타입 Secret은 projected 토큰과 달리 `exp` 필드가 없어 만료되지 않는다. 이 Secret을 calico-node Pod에 마운트하면, VM이 며칠간 suspend 되어도 calico-node가 즉시 API 서버에 인증 가능하고, 기존 CNI 토큰 갱신 메커니즘이 정상 동작한다.

다른 방안을 채택하지 않은 이유:

| 방안 | 불채택 사유 |
|------|------------|
| initContainer로 영구 토큰 kubeconfig 작성 | VM resume 시 Pod 재시작 안 됨 → 실행 안 됨 |
| Sidecar로 주기적 kubeconfig 덮어쓰기 | 동작하지만 노드당 추가 컨테이너 리소스 소비 |
| `CNI_TOKEN_REFRESH_INTERVAL` 단축 | 기본값이 이미 5분. 갱신 주기가 아닌 인증 실패가 문제 |
| `chattr +i`로 kubeconfig 보호 | calico/node 이미지에 chattr 없음, 로그 스팸 |

참고: initContainer/sidecar 시도 시 `calico/cni` 이미지는 scratch 기반으로 `/bin/sh`가 없어 shell 실행 불가. `calico/node`는 busybox 포함이나 `chmod` 등 일부 명령 없음.

## 원본 YAML 대비 변경 내용

대상 파일: `calico-quay-v3.31.2.yaml`

### 1. calico-node-token Secret 추가

ServiceAccount 정의 뒤에 추가.

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

### 2. DaemonSet pod spec에 automountServiceAccountToken: false

projected 토큰 자동 마운트를 비활성화하고, 위 Static Secret을 수동 마운트한다.

```yaml
serviceAccountName: calico-node
automountServiceAccountToken: false   # 추가
```

### 3. 모든 initContainer + container에 volumeMount 추가

**대상 4개소**: `upgrade-ipam`, `install-cni`, `ebpf-bootstrap`, `calico-node`

각 컨테이너의 `volumeMounts:` 끝에 추가:
```yaml
- mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  name: calico-node-token
  readOnly: true
```

### 4. volumes에 calico-node-token 추가

`volumes:` 섹션 끝에 추가:
```yaml
- name: calico-node-token
  secret:
    secretName: calico-node-token
```

## 버전 업그레이드 시 체크리스트

calico 버전을 올릴 때 아래 항목을 반드시 확인한다.

### 반드시 적용할 것

- [ ] `calico-node-token` Secret이 YAML에 포함되어 있는가
- [ ] DaemonSet에 `automountServiceAccountToken: false`가 설정되어 있는가
- [ ] **모든 initContainer**에 `calico-node-token` volumeMount가 있는가
  - 새 버전에서 initContainer가 추가/변경될 수 있음 → 누락 주의
- [ ] `calico-node` 메인 container에 `calico-node-token` volumeMount가 있는가
- [ ] `volumes`에 `calico-node-token` 항목이 있는가

### 확인할 것

- [ ] 새 버전의 `token_watch.go`에서 토큰 유효기간을 외부 설정할 수 있게 되었는지 확인
  - 가능해졌다면 이 수정 전체가 불필요해질 수 있음
- [ ] 새 버전에서 initContainer 목록이 변경되었는지 확인 (추가/제거/이름변경)
- [ ] ServiceAccount 이름이 `calico-node`에서 변경되었는지 확인
  - 변경 시 Secret의 `kubernetes.io/service-account.name` annotation도 수정 필요
