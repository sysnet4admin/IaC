# Changelog

## 2026-03-19: CNI manifests consolidation

Consolidate scattered Calico CNI manifests into `k8s/CNI/archived/`.

### Moved files

| From | To |
|------|----|
| `manifests/172.16_net_calico.yaml` | `k8s/CNI/archived/172.16_net_calico.yaml` |
| `manifests/172.16_net_calico_v1.yaml` | `k8s/CNI/archived/172.16_net_calico_v1.yaml` |
| `manifests/CNI/172.16_net_calico_v3.24.5.yaml` | `k8s/CNI/archived/172.16_net_calico_v3.24.5.yaml` |
| `manifests/CNI/172.16_eht1_net_calico_v3.25.0.yaml` | `k8s/CNI/archived/172.16_eht1_net_calico_v3.25.0.yaml` |

### Removed directories

| Directory | Reason |
|-----------|--------|
| `manifests/CNI/` | Empty after moving all files |

### Modified scripts (IaC internal - 15 files)

Path `raw_git` variable updated: `master/manifests` → `main/k8s/CNI/archived`

| File | Change |
|------|--------|
| `k8s/C/k8s-SingleMaster-1.13.1/master_node.sh` | Hardcoded URL updated |
| `k8s/C/k8s-SingleMaster-18.9_9_w_auto-compl/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-1.16.15-iprange16/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-5GB-1.16.15-iprange1/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-5GiB-1.20.1-iprange1/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-5GiB-1.25.0/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-containerD/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-containerD-only-MST/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-systemd/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-min-post-systemd/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-rook-ceph/master_node.sh` | `raw_git` path updated |
| `k8s/C/k8s-multicontext/master_node.sh` | `raw_git` path updated |
| `k8s/U/k8s-v1.27.0/master_node.sh` | `raw_git` path updated |
| `k8s/U/k8s-multicontext/master_node.sh` | `raw_git` path updated |
| `k8s/U/k8s-multicontext-vagrant-user/master_node.sh` | `raw_git` path updated |

### External repositories requiring update

These repos still reference the old paths and need separate updates:

| Repository | Files | Old Path |
|------------|-------|----------|
| `_Book_k8sInfra` | `ch3/3.1.3/master_node.sh`, `ch3/3.4.1/master_node.sh`, `ch4/4.3.4/.../master_node.sh` | `master/manifests/172.16_net_calico.yaml` |
| `_Book_Claude-Code` | `week1/Thu/ch3/3.1.3/master_node.sh`, `week1/Thu/ch3/3.4.1/master_node.sh`, `week1/Thu/ch4/4.3.4/.../master_node.sh` | `master/manifests/172.16_net_calico.yaml` |
| `_Lecture_k8s_learning.kit` | `A/A.003/C/master_node.sh`, `A/A.003/U/master_node.sh`, `A/A.005/v1.20/CentOS/master_node.sh`, `A/A.005/v1.20/Ubuntu/master_node.sh`, `A/A.011/.../master_node.sh`, `A/A.015/k8s-containerd/master_node.sh`, `A/A.015/k8s-dockershim/master_node.sh`, `X/k8s-multicontext/old-v1.23.1/master_node.sh` | `master/manifests/172.16_net_calico_v1.yaml` |

### Rollback

```bash
git revert <commit-hash>
```
