# IaC
Infrastructure as Code

## Structure
| Directory | Description |
|-----------|-------------|
| `k8s/` | Kubernetes clusters, CNI, manifests, service-mesh |
| `docker/` | Container images & build environments |
| `cicd/` | Argo CD, GitOps, Jenkins |
| `security/` | Keycloak (OIDC), Policy as Code (CEL) |
| `monitoring/` | Prometheus, nGrinder |
| `automation/` | n8n workflow automation |
| `cloud/` | Cloud provider configs (GCP) |
| `AIOps/` | K8sGPT, ChatGPT |
| `bento/` | VM image baking (Packer) |
| `nxosv/` | Cisco NXOSv lab |
| `tools/` | Shell utilities |

## External References
Lab scripts in other repositories download files from `main` while they run: CNI manifests from `k8s/CNI/` and add-on packages and their settings from `k8s/extra-pkgs/<Kubernetes version>/`. Moving, renaming, or deleting these files breaks those labs, and editing them changes the labs.

The books depend on the files below. The lecture kits (`_Lecture_k8s_learning.kit`, `_Lecture_k8s_starter.kit`), `Research`, and `talks` use the same two folders.

| Path | Used by |
|------|---------|
| `k8s/CNI/calico-quay-v3.31.2.yaml` | [_Book_k8sInfra](https://github.com/sysnet4admin/_Book_k8sInfra) `main`: `ch3/3.1.3/controlplane_node.sh` |
| `k8s/CNI/cilium-v1.17.13-w-hubble-lb.yaml` | _Book_k8sInfra `main`: `ch7/7.1.1/controlplane_node.sh` |
| `k8s/extra-pkgs/v1.36/cilium-l2mode.yaml`<br>`k8s/extra-pkgs/v1.36/cilium-iprange.yaml` | _Book_k8sInfra `main`: `ch7/7.1.1/extra_k8s_pkgs.sh` |
| `k8s/extra-pkgs/v1.36/get_helm_v4.2.0.sh` | _Book_k8sInfra `main`: `app/A.console-k8s/k8s_con_pack.sh` |
| `k8s/CNI/archived/172.16_net_calico.yaml` | _Book_k8sInfra `1st-edition` and [_Book_Claude-Code](https://github.com/sysnet4admin/_Book_Claude-Code) `week1/Thu`: `ch3/3.1.3`, `ch3/3.4.1`, `ch4/4.3.4` |
| `tools/k8s_rc.sh`<br>`tools/bash-completion.sh` | _Book_k8sInfra `1st-edition` and _Book_Claude-Code `week1/Thu`: `app/A.kubectl-more` (readers run them with `curl`) |

The 2nd edition book prints the `k8s/CNI` and `k8s/extra-pkgs/v1.36` addresses and file names in its code listings, so keep those paths and names as they are.

## Change History
- Default branch change from `master` to `main` (27 Oct 2023)
