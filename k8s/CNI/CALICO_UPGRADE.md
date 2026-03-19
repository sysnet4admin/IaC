# Calico Upgrade Guide

이 문서는 `calico-quay-v3.31.2.yaml`에 적용된 커스텀 수정 사항을 정의한다.
calico 버전을 업그레이드할 때 새 YAML에 아래 수정을 동일하게 적용해야 한다.

## 배경

calico-node는 projected SA 토큰(3607초)으로 API 서버에 인증하여 CNI 토큰(24h)을 갱신한다.
호스트가 며칠간 suspend 후 resume 되면 projected 토큰이 만료되어 갱신이 실패하고, 새 Pod 배포가 불가능해진다.
이를 해결하기 위해 만료 없는 Static Secret 토큰을 projected 토큰 대신 사용한다.

참고:
- `token_watch.go`의 `defaultCNITokenValiditySeconds = 86400` (하드코딩, 외부 설정 불가)
- https://github.com/projectcalico/calico/issues/8368

## 적용 규칙

새 calico 버전의 원본 YAML을 가져온 뒤, 아래 4단계를 순서대로 적용한다.

### 1. Secret 추가

`kind: ServiceAccount, name: calico-node` 정의 바로 뒤에 아래를 삽입한다.
`kubernetes.io/service-account.name`의 값이 calico-node ServiceAccount 이름과 일치해야 한다.

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

### 2. automountServiceAccountToken 비활성화

`kind: DaemonSet, name: calico-node`의 `spec.template.spec`에서
`serviceAccountName: calico-node` 바로 다음 줄에 추가한다.

```yaml
      automountServiceAccountToken: false
```

### 3. 모든 initContainer와 calico-node container에 volumeMount 추가

`kind: DaemonSet, name: calico-node`의 `spec.template.spec` 아래에 있는
**모든 initContainers 항목**과 **calico-node container**의 `volumeMounts:` 끝에 아래를 추가한다.

v3.31.2 기준 대상: `upgrade-ipam`, `install-cni`, `ebpf-bootstrap`, `calico-node`
새 버전에서 initContainer가 추가/제거/이름변경될 수 있으므로 목록이 아닌 "전체"를 대상으로 한다.

```yaml
            - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
              name: calico-node-token
              readOnly: true
```

### 4. volume 추가

`kind: DaemonSet, name: calico-node`의 `spec.template.spec.volumes:` 끝에 추가한다.

```yaml
        - name: calico-node-token
          secret:
            secretName: calico-node-token
```

## 적용 후 검증

1. `kubectl get secret -n kube-system calico-node-token` 존재 확인
2. `kubectl get ds -n kube-system calico-node -o jsonpath="{.spec.template.spec.automountServiceAccountToken}"` → `false`
3. calico-node Pod 내부 SA 토큰에 `exp` 필드 없음 확인 (영구 유효)
4. busybox 등 테스트 Pod 배포하여 CNI 정상 동작 확인

## 이 수정이 불필요해지는 조건

새 버전의 `token_watch.go`에서 CNI 토큰 유효기간을 외부 설정(env var 등)으로 변경할 수 있게 되었다면, 이 수정 전체를 제거하고 해당 설정을 사용한다.
확인 방법: 새 버전 소스에서 `defaultCNITokenValiditySeconds`가 여전히 하드코딩인지 검색한다.
