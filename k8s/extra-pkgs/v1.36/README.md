### k8s-extra-pkgs (v1.36)

이름            | 버전     | 비고
----            | ----     | ----
kubernetes      | 1.36.x  |
MetalLB         | 0.15.3  |
Ingress-ctrl    | 1.15.1  |
NGINX Gateway   | 2.6.0   | Gateway API v1.5.1 기반 (Ingress-ctrl 대체 가능)
csi-driver-nfs  | 4.13.2   | (nfs-subdir-external-provisioner 대체)
Metrics Server  | 0.8.1    |
Helm            | 4.2.0    |

---

### 기본 manifest 대비 변경 사항

**NGINX Gateway (nginx-gateway-loadbalancer-v2.6.0.yaml):**
- 기본 HTTP Gateway 리소스 추가 (port 80)

**CSI Driver NFS (csi-driver-nfs-v4.13.2.yaml):**
- 없음 (upstream 원본 유지)
