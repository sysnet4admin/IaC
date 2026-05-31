# Cilium Hubble LoadBalancer Variant Guide & Status

이 문서는 Cilium 매니페스트의 변형(variant)과 hubble-ui를 LoadBalancer로 노출하는 구성,
그리고 책 레포(`_Book_k8sInfra` ch7)와의 연동 방식을 기록한다.

## 변형별 상태

| 파일 | hubble-ui Service | 용도 | 비고 |
|---|---|---|---|
| `cilium-v1.17.13-w-hubble.yaml` | `ClusterIP` | Hubble 포함 기본 매니페스트 | 업스트림 Helm 템플릿 출력 그대로 |
| `cilium-v1.17.13-w-hubble-lb.yaml` | `LoadBalancer` | hubble-ui를 외부 노출 | **book ch7/7.1.1에서 사용** |

> 두 파일의 차이는 **단 1줄**이다 (hubble-ui Service `type: ClusterIP` → `LoadBalancer`).
> 검증: `diff cilium-v1.17.13-w-hubble.yaml cilium-v1.17.13-w-hubble-lb.yaml` → 한 줄만 출력.

---

## 배경

book ch7/7.1.1은 `vagrant up` 시 control-plane 프로비저닝에서 Cilium CNI를 적용한다.
기존에는 hubble-ui가 `ClusterIP`로 떠서, 7.2.2 단계에서 별도 스크립트로
`kubectl patch`를 통해 `LoadBalancer`로 바꿔야 했다.

이를 **처음부터(vagrant up 시점) LoadBalancer로 올라오도록** 변경했다.
그 결과 7.2.2의 타입 패치 단계가 불필요해졌다.

### 왜 IP Pool / L2 정책을 이 매니페스트에 넣지 않는가

LoadBalancer Service가 실제 IP를 받으려면 `CiliumLoadBalancerIPPool`과
`CiliumL2AnnouncementPolicy`(베어메탈/VirtualBox라 BGP 없이 L2 ARP 광고) CR이 필요하다.
하지만 **이 CR들을 CNI 매니페스트에 함께 넣어 한 번에 apply하면 실패한다**
— CRD가 등록되기 전에 CR이 적용되기 때문이다 (Operator 제약).

따라서 이 CR들은 별도 파일로 분리되어 있고, book의
`ch7/7.1.1/extra_k8s_pkgs.sh`에서 **시간차(sleep)**를 두고 적용된다:

```bash
# CRD가 먼저 등록될 시간을 확보 (300s도 가능하나 안전구간 540-600s)
(sleep 540 && kubectl apply -f $EXTRA_PKGS_ADDR/cilium-l2mode.yaml)&
(sleep 600 && kubectl apply -f $EXTRA_PKGS_ADDR/cilium-iprange.yaml)&
```

관련 파일 (`k8s/extra-pkgs/v1.32/`):

| 파일 | 리소스 | 값 |
|---|---|---|
| `cilium-iprange.yaml` | `CiliumLoadBalancerIPPool` `k8s-svc-pool` | `192.168.1.11 ~ 192.168.1.99` |
| `cilium-l2mode.yaml` | `CiliumL2AnnouncementPolicy` `layer2-mode` | `interfaces: ^eth[0-9]+`, externalIPs+loadBalancerIPs |

> IP 대역은 vagrant private network(`192.168.1.0/24`)에 속해야 호스트에서 접속 가능하다.
> Pod CIDR(`172.16.0.0/16`)이 아님에 주의. cp=.10, worker=.101~103 과 겹치지 않는 .11~.99 사용.

---

## 동작 흐름 (vagrant up)

1. `controlplane_node.sh` → `cilium-v1.17.13-w-hubble-lb.yaml` 적용.
   hubble-ui가 `LoadBalancer`로 생성되나 IP Pool이 아직 없어 `EXTERNAL-IP`는 `<pending>`.
2. `extra_k8s_pkgs.sh` → sleep 600 후 `k8s-svc-pool` 등장 → LB-IPAM이 hubble-ui에 IP 자동 할당.
3. `7.2.2` → 타입 패치 없이 이미 할당된 LB IP만 출력.

> 초반 약 10분간은 `<pending>` 이 정상이다 (IP Pool 적용 대기). 이후 자동 할당된다.

---

## 적용 규칙 (새 Cilium 버전 업그레이드 시)

1. 새 버전 base 매니페스트(`cilium-vX.Y.Z-w-hubble.yaml`)를 준비한다.
2. 그 파일을 `cilium-vX.Y.Z-w-hubble-lb.yaml`로 복사한다.
3. **hubble-ui Service의 `type: "ClusterIP"` 한 줄만** `type: "LoadBalancer"`로 변경한다.
   대상 식별: `name: hubble-ui` 가 있는 Service 블록 (hubble-relay 등 다른 Service와 혼동 주의).
4. `diff`로 정확히 1줄만 바뀌었는지 검증한다.
5. book `ch7/7.1.1/controlplane_node.sh`의 apply 대상을 새 `-lb` 파일명으로 교체한다.

> IP Pool / L2 정책은 이 매니페스트가 아니라 `k8s/extra-pkgs/`에서 관리되므로,
> 버전 업 시 이쪽은 건드릴 필요 없다 (CRD apiVersion 호환만 확인).

---

## 연동된 book 레포 변경 (`internal-k8s/_Book_k8sInfra`)

| 파일 | 변경 |
|---|---|
| `ch7/7.1.1/controlplane_node.sh` | apply 대상 `w-hubble.yaml` → `w-hubble-lb.yaml` |
| `ch7/7.2.2/configure_cilium_connectvity_env.sh` | hubble-ui 타입 패치 로직 제거 (이미 LB이므로) |

---

## 적용 후 검증

1. `kubectl -n kube-system get svc hubble-ui` → `TYPE` 이 `LoadBalancer`
2. (sleep 600 경과 후) 위 명령의 `EXTERNAL-IP`가 `192.168.1.11~99` 범위 IP로 채워짐
3. `kubectl get ciliumloadbalancerippool` → `k8s-svc-pool` 존재
4. `kubectl get ciliuml2announcementpolicy` → `layer2-mode` 존재
5. 호스트(맥) 브라우저에서 `http://<EXTERNAL-IP>` 로 Hubble UI 접속 확인
