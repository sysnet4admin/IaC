# Ubuntu 24.04 Vagrant Box 빌드 아키텍처 결정

## 결론

| 아키텍처 | 빌드 방법 | 이유 |
|---|---|---|
| **x86_64** | GitHub Actions (ubuntu-latest) | VirtualBox Linux amd64 정상 동작 |
| **aarch64** | 로컬 Mac M-series (수동) | VirtualBox Linux arm64 미지원. QEMU로는 Actions에서 3시간 19분 (2026-11-04 시험) |

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

2. **GitHub arm64 runner (`ubuntu-24.04-arm`)에서 VirtualBox 사용 불가**
   - Azure 기반 arm64 Linux VM
   - VirtualBox 설치 자체가 불가능 (7.2.8에도 Linux arm64 패키지 없음, 2026-11-04 확인)
   - QEMU로는 빌드된다. 다만 KVM이 없어 3시간 19분 걸린다 (아래 "QEMU로 빌드하는 시험")

3. **GitHub macOS arm64 runner 사용 불가**
   - 중첩 가상화를 지원하지 않는다 (GitHub 문서 "Limitations for arm64 macOS runners")

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

**QEMU로 빌드하는 시험 (2026-11-04):**

x86_64처럼 QEMU로 빌드한 뒤 VirtualBox box로 묶는 방법을 `ubuntu-24.04-arm` 러너에서 시험했다.
템플릿은 `ubuntu-24.04-aarch64-qemu.pkr.hcl`, 워크플로는 `.github/workflows/build-ubuntu-24.04-arm64.yml`이다.
워크플로는 Mac을 사용할 수 없을 때 손으로 실행한다(`workflow_dispatch`). 업로드 단계는 없고 box는 artifact로 7일 남는다.
빌드는 되고 box도 동작한다. 러너에 `/dev/kvm`이 없어 QEMU가 에뮬레이션(TCG)으로 돌기 때문에 3시간 19분이 걸린다.

| 항목 | 값 |
|---|---|
| 러너 | `ubuntu-24.04-arm` (Neoverse-N2 4 vCPU, 메모리 16 GB, KVM 없음) |
| QEMU | `-machine virt,accel=tcg -cpu max,pauth-impdef=on -smp 4` |
| ISO 받기, 부팅 명령 | 3분 |
| 설치 (autoinstall, SSH 연결까지) | 2시간 24분 |
| `update_ubuntu.sh` | 34분 |
| 나머지 스크립트, zero-fill | 18분 |
| packer build 합계 | 3시간 19분 |
| box로 묶기 | 1분 33초 |
| box 크기 | 956,804,113 bytes (v1.0.0 arm64는 968,788,037 bytes) |

만든 box를 Apple Silicon Mac(VirtualBox 7.2.8, Vagrant 2.4.9)에서 확인했다.

- VirtualBox ARM VM에서 부팅한다. QEMU에서 만든 EFI 부팅 항목은 따라오지 않지만 `EFI/BOOT/BOOTAA64.EFI`(shim)로 부팅한다.
- `eth0`과 `eth1`(private_network)이 올라오고 인터넷에 연결된다.
- kubeadm으로 Kubernetes 1.36.0 클러스터(control-plane 1대, worker 3대)를 올렸고 노드가 모두 Ready다.

x86_64 템플릿과 다르게 한 것은 이렇다.

- `virt` 머신에는 IDE가 없다. 디스크는 virtio-blk, ISO는 virtio-scsi로 붙인다. 둘 다 `if=virtio`로 붙이면 index 0이 겹쳐 QEMU가 시작하지 않는다.
- `virt` 머신에는 화면과 키보드가 없다. `boot_command`(VNC)를 보내려고 `virtio-gpu-pci`, `qemu-xhci`, `usb-kbd`를 붙인다.
- CPU는 `max,pauth-impdef=on`이다. Ubuntu 24.04 arm64 패키지는 포인터 인증(PAC) 명령을 사용하는데 `-cpu max`의 기본 알고리즘(QARMA5)은 에뮬레이션에서 매우 느리다. `-cpu max`로는 설치가 5시간 안에 끝나지 않았다(보안 업데이트 단계에서 soft lockup).
- 에뮬레이션은 부팅이 느려 GRUB 메뉴가 뜨는 시점이 일정하지 않다. `<wait5><up>`을 반복해 30초 자동 부팅을 멈춘 뒤 편집한다.
- Linux arm64용 VirtualBox가 없어 VBoxManage로 묶을 수 없다. `qemu-img`로 streamOptimized VMDK를 만들고 `box.ovf`, `Vagrantfile`, `metadata.json`은 v1.0.0 arm64 box의 것을 사용한다(디스크 파일 이름과 크기 64 GiB가 같다). `box.ovf`의 VRDE 인증서 경로 2줄은 빌드한 Mac의 로컬 경로라 지운다.

시험하지 않은 것: 24.04.5 ISO를 사용하면 설치 중 업데이트 양이 줄어 시간이 짧아질 수 있다.

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
