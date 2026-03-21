# Calico Upgrade Guide

이 문서는 `calico-quay-v3.31.2.yaml`에 적용된 커스텀 수정 사항을 정의한다.
calico 버전을 업그레이드할 때 새 YAML에 아래 수정을 동일하게 적용해야 한다.

## 배경

calico-node는 projected SA 토큰(3607초)으로 API 서버에 인증하여 CNI 토큰(24h)을 갱신한다.
호스트가 suspend 후 resume 되면 두 가지 문제가 발생한다:

1. **projected 토큰 만료(>1h suspend)**: calico-node가 API 서버에 인증 불가 → CNI 토큰 갱신 불가
2. **CNI 토큰 만료(>24h suspend)**: calico-kubeconfig의 토큰이 만료 → 새 Pod 배포 불가

두 문제를 모두 해결하기 위해 만료 없는 Static Secret 토큰을 사용한다:
- `calico-node-token`: calico-node의 인증 토큰 (projected 3607s 대체)
- `calico-cni-plugin-token`: calico-kubeconfig의 CNI 토큰 (24h TokenRequest 대체)

참고:
- `token_watch.go`의 `defaultCNITokenValiditySeconds = 86400` (하드코딩, 외부 설정 불가)
- https://github.com/projectcalico/calico/issues/8368

## 적용 규칙

새 calico 버전의 원본 YAML을 가져온 뒤, 아래 6단계를 순서대로 적용한다.

### 1. calico-node-token Secret 추가

`kind: ServiceAccount, name: calico-node` 정의 바로 뒤에 아래를 삽입한다.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: calico-node-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: calico-node
type: kubernetes.io/service-account-token
```

### 2. calico-cni-plugin-token Secret 추가

`calico-node-token` Secret 바로 뒤에 아래를 삽입한다.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: calico-cni-plugin-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: calico-cni-plugin
type: kubernetes.io/service-account-token
```

### 3. automountServiceAccountToken 비활성화

`kind: DaemonSet, name: calico-node`의 `spec.template.spec`에서
`serviceAccountName: calico-node` 바로 다음 줄에 추가한다.

```yaml
      automountServiceAccountToken: false
```

### 4. 모든 initContainer와 calico-node container에 calico-node-token volumeMount 추가

`kind: DaemonSet, name: calico-node`의 **모든 initContainers 항목**과
**calico-node container**의 `volumeMounts:` 끝에 아래를 추가한다.

v3.31.2 기준 대상: `upgrade-ipam`, `install-cni`, `ebpf-bootstrap`, `calico-node`
새 버전에서 initContainer가 추가/제거/이름변경될 수 있으므로 목록이 아닌 "전체"를 대상으로 한다.

```yaml
            - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
              name: calico-node-token
              readOnly: true
```

### 5. patch-cni-kubeconfig init container 추가

`install-cni` initContainer 정의 바로 뒤에 아래를 삽입한다.
install-cni가 작성한 calico-kubeconfig의 24h 토큰을 static 토큰으로 교체한다.
또한 install-cni가 서버 URL을 `https://[IPv4]:port` 형식으로 쓰는 경우 수정한다
(Go의 net.JoinHostPort 출력이 Calico CNI 파서와 호환되지 않는 문제).

```yaml
        - name: patch-cni-kubeconfig
          image: busybox:1.37
          imagePullPolicy: IfNotPresent
          command: ["/bin/sh", "-c"]
          args:
            - |
              STATIC_TOKEN=$(cat /var/run/secrets/calico-cni-plugin/token)
              sed -i "s|    token:.*|    token: $STATIC_TOKEN|" /host/etc/cni/net.d/calico-kubeconfig
              sed -i 's|server: https://\[\([0-9.]*\)\]:\([0-9]*\)|server: https://\1:\2|' /host/etc/cni/net.d/calico-kubeconfig
              echo "patch-cni-kubeconfig: replaced token with static calico-cni-plugin token (no expiry), fixed server URL format"
          volumeMounts:
            - mountPath: /host/etc/cni/net.d
              name: cni-net-dir
            - mountPath: /var/run/secrets/calico-cni-plugin
              name: calico-cni-plugin-token
              readOnly: true
          securityContext:
            privileged: true
```

### 6. cni-net-dir를 readOnly로 변경 및 volume 2개 추가

#### 6-1. calico-node main container의 cni-net-dir를 readOnly로 변경

`kind: DaemonSet, name: calico-node`의 **calico-node container** volumeMounts에서
cni-net-dir의 `readOnly: false`를 `readOnly: true`로 변경한다.

token_watch.go가 calico-kubeconfig를 새 24h 토큰으로 덮어쓰지 못하게 막기 위함이다.

```yaml
            - mountPath: /host/etc/cni/net.d
              name: cni-net-dir
              readOnly: true
```

#### 6-2. volumes에 두 Secret 추가

`spec.template.spec.volumes:` 끝에 아래 두 항목을 추가한다.

```yaml
        - name: calico-node-token
          secret:
            secretName: calico-node-token
        - name: calico-cni-plugin-token
          secret:
            secretName: calico-cni-plugin-token
```

## 적용 후 검증

1. `kubectl get secret -n kube-system calico-node-token calico-cni-plugin-token` 존재 확인
2. `kubectl get ds -n kube-system calico-node -o jsonpath="{.spec.template.spec.automountServiceAccountToken}"` → `false`
3. 각 노드의 `/etc/cni/net.d/calico-kubeconfig` 토큰에 `exp` 필드 없음 확인 (영구 유효)
4. 서버 URL이 `https://IP:port` 형식인지 확인 (괄호 없음)
5. Pod 배포하여 CNI 정상 동작 확인

## 이 수정이 불필요해지는 조건

새 버전의 `token_watch.go`에서 CNI 토큰 유효기간을 외부 설정(env var 등)으로 변경할 수 있게 되었다면,
단계 2, 5, 6-1, 6-2(calico-cni-plugin-token 부분)를 제거하고 해당 설정을 사용한다.
확인 방법: 새 버전 소스에서 `defaultCNITokenValiditySeconds`가 여전히 하드코딩인지 검색한다.
