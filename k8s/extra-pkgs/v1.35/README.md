### k8s-extra-pkgs (v1.35)

이름            | 버전     | 비고
----            | ----     | ----
kubernetes      | 1.35.x  |
MetalLB         | 0.15.3  |
Ingress-ctrl    | 1.14.1  |
NGINX Gateway   | 2.3.0   | Gateway API v1.4.1 기반 (Ingress-ctrl 대체 가능)
csi-driver-nfs  | 4.12.1   | (nfs-subdir-external-provisioner 대체)
Metrics Server  | 0.8.0    |
Helm            | 4.0.4    |

---

### 기본 manifest 대비 변경 사항

**NGINX Gateway (nginx-gateway-loadbalancer-v2.3.0.yaml):**
- 기본 HTTP Gateway 리소스 추가 (port 80)

**CSI Driver NFS (csi-driver-nfs-v4.12.1.yaml):**
- 없음 (upstream 원본 유지)
