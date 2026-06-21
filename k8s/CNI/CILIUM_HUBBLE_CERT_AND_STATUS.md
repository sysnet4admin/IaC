# Cilium Hubble 인증서 갱신 Guide & Status

이 문서는 suspend/resume(또는 장기 운영) 환경에서 발생하는 Cilium **Hubble mTLS 인증서 만료**
이슈의 해결 방법과 버전별 적용 상태를 기록한다. Calico 토큰 만료 이슈
([CALICO_PATCH_AND_STATUS.md](./CALICO_PATCH_AND_STATUS.md))와 **근본 원인은 같으나 해결 난이도가
크게 다르다** — 그 차이를 함께 정리한다.

## 버전별 인증서 상태

| 파일 | Hubble cert 유효기간 | 비고 |
|---|---|---|
| `cilium-v1.17.13-w-hubble-lb.yaml` | 전부 2026-06-20 ~ **2100-12-31** | **현재 사용 버전** (book ch7/7.1.1). 2026-06-21 cert 교체 완료 |
| `cilium-v1.17.13-w-hubble.yaml` (base, ClusterIP) | 전부 2026-06-20 ~ **2100-12-31** | 동일 CA로 갱신. -lb와 hubble-ui Service type 1줄만 차이 |

> 교체 전 두 파일은 server·client cert가 2026-06-08 만료(발급일 2025-06-08, 1년)였다.
> 2026-06-21 기준 이미 만료 상태였고, 위와 같이 2100년 cert로 교체했다.

> Hubble 인증서는 Helm `tls.auto.method=helm` 방식으로 **렌더 시점에 생성되어 static Secret으로
> 매니페스트에 박혀** 있다. 즉 클러스터 안에 cert를 재생성하는 컴포넌트가 없으므로, Secret의
> cert 데이터만 교체하면 영구 유지된다 (아래 "Calico와의 차이" 참조).

---

## 배경

Hubble는 관측성(observability) 컴포넌트로, 다음 3개 컴포넌트가 mTLS로 통신한다:

- cilium-agent의 Hubble **server** (`hubble-server-certs`)
- **hubble-relay** 가 server에 붙는 client (`hubble-relay-client-certs`)
- 위 둘을 서명한 **CA** (`cilium-ca`)

이 매니페스트의 cert는 server/client가 **1년** 유효다. 발급일(2025-06-08)로부터 1년이 지나면
(=2026-06-08) Hubble Relay ↔ cilium-agent mTLS 핸드셰이크가 실패하여 **Hubble UI / `hubble observe`
가 동작하지 않는다**. (단, Pod 네트워킹 자체는 Hubble와 무관하므로 영향 없음.)

해결: cert를 **2100년 만료**로 재발급해 Secret 데이터를 통째 교체한다.

```bash
# cert 재발급 예시 (cilium CLI 또는 cilium-certgen 사용)
# CA를 새로 만들고 server/client cert를 장기 유효기간으로 서명한 뒤
# hubble-server-certs / hubble-relay-client-certs / cilium-ca Secret을 교체
```

---

## Calico와의 차이 — 왜 Cilium은 구조 수술이 불필요한가

| | Cilium (Hubble) | Calico |
|---|---|---|
| 만료 대상 | mTLS **인증서** (CA 3년 / server·client 1년) | SA **토큰** (projected 3607s / CNI 24h) |
| **자격증명을 런타임에 재생성하는 주체** | **없음** (`tls.auto.method=helm`, static Secret) | **있음** — calico-node `token_watch.go`가 kubeconfig를 새 24h 토큰으로 주기적으로 덮어씀 |
| 그래서 "기간만 교체"하면? | **유지됨** — 아무도 안 덮어씀 | **무효화됨** — 에이전트가 곧 짧은 토큰으로 갈아엎음 |
| 필요한 작업 | Secret cert **데이터만 교체** (파일 1개 apply) | DaemonSet 구조 수술 6단계 (Secret 추가 + automount off + init container + cni-net-dir readOnly) |
| 버전 업 시 재적용 | 불필요 (cert는 데이터일 뿐) | **매번 재적용** (`defaultCNITokenValiditySeconds=86400` 하드코딩 유지되는 한) |

핵심: **"단기 자격증명을 다시 쓰는 살아있는 컴포넌트가 있느냐"** 가 분기점이다.
Calico는 `token_watch.go`라는 재생성 주체가 있어서 토큰을 길게 넣어도 곧 덮어쓰이므로, 재생성
메커니즘 자체를 막는 구조 수술이 필요했다. 반면 이 Cilium 매니페스트는 cert를 재생성하는
주체(certgen CronJob / cert-manager 등)가 **존재하지 않으므로** cert 데이터 교체만으로 충분하다.

### 검증 근거 (`cilium-v1.17.13-w-hubble-lb.yaml`)

| 검사 | 결과 | 명령/위치 |
|---|---|---|
| Job / CronJob | 0개 | `grep -E '^kind: (Job\|CronJob)'` |
| `certgen` ServiceAccount | 없음 (cilium/envoy/operator/hubble-relay/hubble-ui뿐) | `grep -A1 'kind: ServiceAccount'` |
| cert-manager 참조 | 0개 | `grep -c cert-manager` |
| Secret 출처 | `templates/hubble/tls-helm/...` = **helm 방식** | Secret 위 `# Source:` 주석 |
| Secret RBAC verbs | `get/list/watch`만 (update/patch/create 없음) | cilium-secrets Role |
| cert 소비 방식 | secret volume **read-only 마운트** | hubble-server-certs / hubble-relay-client-certs |

---

## 적용 규칙

새 Cilium 버전이나 만료된 cert를 교체할 때 아래를 따른다.

1. cert를 장기 유효기간으로 재발급한다 (`cilium-ca`, `hubble-server-certs`,
   `hubble-relay-client-certs` 3개 Secret의 `ca.crt`/`tls.crt`/`tls.key`).
2. 매니페스트의 해당 Secret 데이터만 새 값으로 교체한다 (구조/볼륨/RBAC 변경 없음).
3. `diff` 시 **cert/key 라인만** 바뀌었는지 확인한다.
4. book `ch7/7.1.1/controlplane_node.sh`의 apply 대상을 새 파일명으로 교체한다.

> **주의 — `tls.auto.method=cronJob` 으로 바꾸면 이 결론이 깨진다.** 그 경우
> `cilium-certgen` CronJob이 cert를 주기적으로 재생성하므로(=Calico의 token_watch와 동일한
> 재생성 주체 등장), 우리가 박은 장기 cert를 단기 cert로 덮어쓴다. 반드시 `method=helm` 유지.

---

## 적용 후 검증

1. `kubectl -n kube-system get secret cilium-ca hubble-server-certs hubble-relay-client-certs` 존재 확인
2. cert 유효기간 확인:
   ```bash
   kubectl -n kube-system get secret hubble-server-certs -o jsonpath='{.data.tls\.crt}' \
     | base64 -d | openssl x509 -noout -dates
   ```
   → `notAfter`가 2100년인지 확인
3. **재생성 주체 부재 확인**: `kubectl get cronjob,job -n kube-system` → certgen 관련 없음
4. **덮어쓰기 없음 확인**: cilium / hubble-relay Pod 재시작 후에도 위 cert가 2100년 그대로인지
5. Hubble 동작 확인: `hubble status`, `hubble observe`, Hubble UI 접속

---

## 이 패치(cert 교체)가 불필요/위험해지는 조건

- **Helm으로 재배포**하거나 `tls.auto.method`를 `cronJob`/`certmanager`로 바꾸면, cert를 재생성하는
  주체가 생겨 장기 cert가 덮어쓰인다 → 이 환경은 **매니페스트 직접 apply 방식만 유지**해야 한다.
- 업스트림이 짧은 cert + 자동 갱신을 강제하는 방향으로 가면(예: certgen 필수화), Calico처럼
  "재생성 차단" 전략이 필요해질 수 있다. 그때는 본 문서의 가정(재생성 주체 부재)을 재검증한다.

---

## 실측 테스트 결과 (book ch7/7.1.1 클러스터)

> 아래는 `_Book_k8sInfra/ch7/7.1.1` 클러스터(k8s 1.36.1, CP1+Worker3, VirtualBox)에 직접 올려
> 검증한 결과다. (검증일 2026-06-21)

### 1) 문제 재현 — 만료 cert 상태

`controlplane_node.sh`가 적용하는 `cilium-v1.17.13-w-hubble-lb.yaml`(server·client cert 2026-06-08
만료)로 올린 직후:

- `hubble-relay` Pod가 `0/1` + 재시작 발생
- relay 로그:
  ```
  tls: failed to verify certificate: x509: certificate has expired or is not yet valid:
  current time 2026-06-21T... is after 2026-06-08T22:55:35Z
  ```
- → **Pod 네트워킹은 정상**(노드 4대 Ready, Pod 통신 OK), Hubble observability만 깨짐. 예상과 일치.

### 2) 해결 검증 — 2100년 cert 교체

2100년 cert 버전(현재 `cilium-v1.17.13-w-hubble-lb.yaml`에 반영된 내용) 적용 결과:

- `kubectl apply` 출력: **`secret/cilium-ca` / `hubble-relay-client-certs` / `hubble-server-certs`
  3개만 `configured`**, 나머지 리소스는 전부 `unchanged` → cert 데이터만 교체됨을 확인.
- 라이브 cert `notAfter`가 **2100-12-31**로 변경.
- `ds/cilium` + `deploy/hubble-relay` 재시작 후 hubble-relay `1/1 Running`, 로그에
  `hubble-tls=true Connected` 로 4개 노드 피어 전부 연결. **cert 에러 사라짐.**

### 3) 재생성 주체 부재 검증 (Calico와의 결정적 차이)

| 검증 | 결과 |
|---|---|
| 클러스터 전체 `kubectl get cronjob,job -A` | **No resources found** (cert 재생성 배치 없음) |
| `cilium-operator` 로그의 Secret 동기화 대상 | `CiliumNetworkPolicy → cilium-secrets`(정책 TLS)뿐, **Hubble cert secret은 비관리** |
| **`hubble-server-certs` Secret 삭제 후 20초 대기** | **재생성 안 됨 (`NotFound` 유지)** |

> 마지막 항목이 핵심이다. **Calico였다면 `token_watch.go`가 삭제/변경된 자격증명을 수 초 내
> 재생성**한다. Cilium은 삭제해도 아무도 되살리지 않았다 → Hubble cert를 다시 쓰는 살아있는
> 주체가 **존재하지 않음**이 실측으로 증명됨. (삭제 후 `2100y.yaml` 재apply로 즉시 복구.)

### 결론

- 이 매니페스트(`tls.auto.method=helm`)에서 **Hubble cert는 데이터 교체만으로 영구 해결**된다.
  Calico처럼 "재생성 메커니즘을 차단하는 구조 수술"이 **불필요**하다.
- 단, 전제는 **재생성 주체가 없을 것**. `method=cronJob`/`certmanager`로 바꾸거나 Helm으로
  재배포하면 이 전제가 깨지므로(certgen이 cert를 덮어씀), 매니페스트 직접 apply 방식을 유지한다.
