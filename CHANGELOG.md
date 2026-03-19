# Changelog

## 2026-03-19: Organize k8s/ subdirectories

Group cluster-related dirs under `k8s/clusters/`.

| From | To |
|------|----|
| `k8s/C/` | `k8s/clusters/C/` |
| `k8s/U/` | `k8s/clusters/U/` |
| `k8s/kwok/` | `k8s/clusters/kwok/` |
| `k8s/k8s-console/` | `k8s/clusters/consoles/k8s-console/` |
| `k8s/t7m-console/` | `k8s/clusters/consoles/t7m-console/` |

Unchanged (external references): `CNI/`, `extra-pkgs/`

---

## 2026-03-19: Move terraform console to k8s/

| From | To | Reason |
|------|----|--------|
| `terraform/t7m-Console/` | `k8s/t7m-console/` | Vagrant-based tool console, same pattern as `k8s/k8s-console/` |

Removed `terraform/` directory (empty after move).

---

## 2026-03-19: Repository folder restructuring

Reorganize top-level directories from 20 to 12 by grouping related components.

### Moved directories

| From | To | Reason |
|------|----|--------|
| `manifests/*` | `k8s/manifests/` | K8s manifests belong under k8s |
| `Cloud-Native/Samples/` | `k8s/service-mesh/Samples/` | Istio samples → service-mesh under k8s |
| `Argo/argo-cd/` | `cicd/argo-cd/` | CI/CD consolidation |
| `GitOps/` | `cicd/gitops/` | CI/CD consolidation |
| `Jenkins/dev-to-prod/` | `cicd/jenkins/` | CI/CD consolidation |
| `PaC/` | `security/pac/` | Security consolidation |
| `Keycloak/` | `security/keycloak/` | Security consolidation |
| `Prometheus/` | `monitoring/prometheus/` | Monitoring consolidation |
| `nGrinder/` | `monitoring/ngrinder/` | Monitoring consolidation |
| `n8n/` | `automation/n8n/` | Automation category |
| `GCP/` | `cloud/gcp/` | Cloud provider category |
| `Docker/` | `docker/` | Lowercase normalization |
| `Bento/` | `bento/` | Lowercase normalization |
| `Terraform/` | `terraform/` | Lowercase normalization |
| `NXOSv/` | `nxosv/` | Lowercase normalization |

### Removed directories

| Directory | Reason |
|-----------|--------|
| `manifests/` | Empty after absorption into `k8s/manifests/` |
| `Cloud-Native/` | Empty after move |
| `Argo/` | Empty after move |
| `Jenkins/` | Empty after move |

### Unchanged

| Directory | Reason |
|-----------|--------|
| `k8s/` | Core — stays at root |
| `AIOps/` | To be reorganized later |
| `tools/` | Already well-placed |

### External repositories updated

| Repository | File | Change |
|------------|------|--------|
| `talks` | `KubeCon/2023-NA/DEMO/README.md` | `Keycloak/` → `security/keycloak/` link |
| `_Book_k8sInfra` | `app/A.kubectl-more/bash-completion.sh`, `k8s_rc.sh` | Comment URL path updated |
| `_Book_Claude-Code` | `week1/Thu/app/A.kubectl-more/bash-completion.sh`, `k8s_rc.sh` | Comment URL path updated |

### Rollback

```bash
git revert <commit-hash>
```

---

## 2026-03-19: Move bash-completion.sh to tools/

Move kubectl helper script from `manifests/` to `tools/` where other shell utilities reside.

| From | To |
|------|----|
| `manifests/bash-completion.sh` | `tools/bash-completion.sh` |

Usage comment URL updated: `master/manifests/` → `main/tools/`

External repos with copies (comment-only reference, no runtime impact):
- `_Book_k8sInfra`: `app/A.kubectl-more/bash-completion.sh`
- `_Book_Claude-Code`: `week1/Thu/app/A.kubectl-more/bash-completion.sh`

---

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
