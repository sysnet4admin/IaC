# Ubuntu 24.04 Vagrant Box 빌드 아키텍처 결정

## 결론

| 아키텍처 | 빌드 방법 | 이유 |
|---|---|---|
| **x86_64** | GitHub Actions (ubuntu-latest) | VirtualBox Linux amd64 정상 동작 |
| **aarch64** | 로컬 Mac M-series (수동) | VirtualBox Linux arm64 미지원 |

---

## 아키텍처별 상세

### x86_64 (GitHub Actions)

워크플로우: `.github/workflows/build-ubuntu-24.04.yml`

**해결한 이슈:**

1. **KVM 충돌** (`VERR_SVM_IN_USE`)
   - GitHub-hosted runner는 KVM이 이미 활성화된 상태
   - VirtualBox와 KVM은 하드웨어 가상화를 동시에 점유할 수 없음
   - 해결: packer 빌드 전 KVM 모듈 언로드
     ```bash
     sudo rmmod kvm_amd || sudo rmmod kvm_intel || true
     sudo rmmod kvm || true
     ```

2. **SSH 타임아웃** (`Timeout waiting for SSH`)
   - 기본값 15분으로는 GitHub Actions 환경의 느린 디스크/네트워크로 인해 Ubuntu autoinstall 미완료
   - 해결: `-var "ssh_timeout=60m"` 으로 override

### aarch64 (로컬 Mac M-series)

**GitHub-hosted runner를 사용할 수 없는 이유:**

1. **VirtualBox Linux arm64 host 미지원**
   - VirtualBox 7.1에서 arm64 지원이 추가됐으나 **macOS arm64 host 전용**
   - Linux arm64 host용 패키지가 존재하지 않음
   - `https://download.virtualbox.org/virtualbox/7.1.6/` 에 Linux arm64 .deb 없음

2. **GitHub arm64 runner (`ubuntu-24.04-arm`) 사용 불가**
   - Azure 기반 arm64 Linux VM
   - VirtualBox 설치 자체가 불가능

**로컬 빌드 방법:**
```bash
cd /Users/hj/11.Github/IaC/bento/bento
packer build \
  -only=virtualbox-iso.vm \
  -var-file=os_pkrvars/ubuntu/ubuntu-24.04-aarch64.pkrvars.hcl \
  packer_templates/
```
- ISO: `/Users/hj/Documents/vagrant_cloud/iso/ubuntu-24.04.4-live-server-arm64.iso` (로컬)
- 빌드 결과: `builds/ubuntu-24.04-aarch64.virtualbox.box`

---

## Ubuntu 24.04 박스 변경사항 (22.04 대비)

### custom_post_hoon.sh에 추가된 sshd symlink

```bash
# Ubuntu 24.04부터 sshd.service alias가 제거됨 (22.04까지는 ssh.service의 alias로 존재했음)
# provisioning 스크립트에서 'systemctl reload sshd' 등을 그대로 사용할 수 있도록
# 박스 빌드 시점에 symlink를 생성해 호환성 확보
ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/sshd.service 2>/dev/null || true
systemctl daemon-reload
```

**배경:**
- Ubuntu 22.04: `sshd.service`가 `ssh.service`의 alias로 존재 → `systemctl reload sshd` 동작
- Ubuntu 24.04: SSH가 소켓 기반 활성화(socket-activated)로 변경되면서 `sshd` alias 제거
- 박스에 symlink를 미리 생성해두면 provisioning 스크립트 수정 없이 그대로 사용 가능

### pkr-builder.pkr.hcl에서 제거된 스크립트

ubuntu/debian 빌드에서 아래 3개 스크립트 제거:
- `virtualbox.sh` — VirtualBox Guest Additions (synced_folder 미사용이므로 불필요)
- `vmware.sh` — VMware Tools (불필요)
- `parallels.sh` — Parallels Tools (불필요)

Guest Additions가 없어도 네트워크/SSH는 정상 동작. Vagrant synced_folder는 모든 Vagrantfile에서 `disabled: true`.

---

## Vagrant Cloud 업로드

HCP Service Principal 인증 사용 (`HCP_CLIENT_ID`, `HCP_CLIENT_SECRET`):

```bash
# 1. HCP 토큰 획득
TOKEN=$(curl -sf \
  --request POST \
  --url "https://auth.idp.hashicorp.com/oauth2/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "client_id=<HCP_CLIENT_ID>&client_secret=<HCP_CLIENT_SECRET>&grant_type=client_credentials&audience=https://api.hashicorp.cloud" \
  | jq -r '.access_token')

# 2. 업로드
VAGRANT_CLOUD_TOKEN=$TOKEN vagrant cloud publish \
  sysnet4admin/Ubuntu-k8s-2404-test \
  0.0.1 virtualbox \
  builds/ubuntu-24.04-x86_64.virtualbox.box \
  --release --force
```

x86_64: GitHub Actions 자동화
aarch64: 로컬 빌드 후 위 명령으로 수동 업로드
