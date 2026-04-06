# Ubuntu 24.04 Vagrant Box 빌드 가이드 (x86_64 + arm64)

> 최종 업데이트: 2026-04-07  
> 목적: Claude Code가 이 문서를 읽고 x86_64/arm64 빌드를 각각 수행할 수 있도록 정리  
> Vagrant Cloud: `sysnet4admin/Ubuntu-k8s` (프로덕션), `sysnet4admin/Ubuntu-k8s-2404-test` (테스트)

---

## 현재 상태 (빠른 참조)

| 항목 | x86_64 (amd64) | arm64 (aarch64) |
|---|---|---|
| **프로덕션 버전** | **v1.0.0** ✅ | **v1.0.0** ✅ |
| **Vagrant Cloud 박스** | `sysnet4admin/Ubuntu-k8s` | `sysnet4admin/Ubuntu-k8s` |
| **architecture 태그** | `amd64` | `arm64` (default_architecture) |
| **동작 확인** | x86_64 랩탑에서 vagrant up 통과 | 클러스터 테스트 통과 |
| **로컬 box 파일** | — (GitHub Actions 빌드) | `/Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v1.0.0.box` |

### 다음 버전(v1.0.1 등) 배포 절차

**x86_64**: GitHub Actions 워크플로우 트리거 (아래 섹션 1 참고)  
**arm64**: 로컬 Mac에서 수동 빌드 후 업로드 (아래 섹션 2 참고)

---

## 아키텍처별 빌드 요약

| 항목 | x86_64 | arm64 (aarch64) |
|---|---|---|
| **빌드 환경** | GitHub Actions (`ubuntu-latest`, 네이티브 KVM) | 로컬 Mac M-series (수동) |
| **빌더** | QEMU/KVM (전용 템플릿) | VirtualBox (bento upstream 템플릿) |
| **Packer 템플릿** | `bento/ubuntu-24.04-x86_64-qemu.pkr.hcl` | `bento/bento/packer_templates/` + pkrvars |
| **워크플로우** | `.github/workflows/build-ubuntu-24.04.yml` | 없음 (수동) |
| **업로드 방식** | 워크플로우 내 자동 | 로컬에서 `vagrant cloud publish` |
| **architecture 플래그** | `--architecture amd64` | `--architecture arm64` |
| **빌드 시간** | ~14분 | ~9분 |
| **용량** | ~900MB (빌드 시점 패키지마다 ±80MB) | 924MB (v1.0.0) |

---

## 1. x86_64 빌드 (GitHub Actions)

### 파일 구조

```
IaC/
├── .github/workflows/build-ubuntu-24.04.yml   # GitHub Actions 워크플로우
└── bento/
    ├── ubuntu-24.04-x86_64-qemu.pkr.hcl       # QEMU/KVM 전용 Packer 템플릿
    └── bento/packer_templates/
        ├── http/ubuntu/user-data               # autoinstall cloud-init 설정
        └── scripts/                            # provisioning 스크립트 (공용)
```

### 실행 방법 (신규 버전 배포)

GitHub Actions → **"Build Ubuntu 24.04 Vagrant Box"** → **Run workflow**:

| 입력 | 값 | 기본값 |
|---|---|---|
| `version` | 새 버전 (예: `1.0.1`) | `1.0.0` |
| `box_name` | `sysnet4admin/Ubuntu-k8s` (프로덕션) 또는 `sysnet4admin/Ubuntu-k8s-2404-test` (테스트) | `sysnet4admin/Ubuntu-k8s` |

> **테스트가 필요한 경우**: `box_name`을 `sysnet4admin/Ubuntu-k8s-2404-test`로 변경하여 먼저 확인.

### 워크플로우 핵심 플로우

```
GitHub Actions (ubuntu-latest, 네이티브 KVM)
  ↓ packer build (QEMU/KVM)
ubuntu-24.04-amd64.qcow2
  ↓ inline zero-fill provisioner (dd if=/dev/zero)
  ↓ qemu-img convert -o subformat=streamOptimized  ← 필수 (없으면 runner 죽음)
ubuntu-24.04-amd64.vmdk
  ↓ VBoxManage createvm → OVA export
  ↓ tar xf → mv *.ovf box.ovf → mv *.vmdk box-disk001.vmdk  ← Vagrant 규격 필수
  ↓ tar cf - | gzip -9
ubuntu-24.04-x86_64.virtualbox.box
  ↓ vagrant cloud publish --architecture amd64 --release --force
sysnet4admin/Ubuntu-k8s vX.X.X (amd64)
```

### 필수 Secrets (IaC repo Settings > Secrets)

| Secret | 용도 |
|---|---|
| `HCP_CLIENT_ID` | Vagrant Cloud HCP 인증 |
| `HCP_CLIENT_SECRET` | Vagrant Cloud HCP 인증 |
| `GITHUB_TOKEN` | Packer init API rate limit 방지 (자동 제공) |

### QEMU 템플릿 핵심 설정

```hcl
source "qemu" "ubuntu24" {
  accelerator    = "kvm"      # GitHub Actions 네이티브 KVM
  headless       = true
  disk_size      = "65536M"
  http_directory = "bento/packer_templates/http"
  # QEMU user networking에서 호스트는 항상 10.0.2.2
  boot_command   = ["...autoinstall ds=nocloud-net;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/..."]
}
```

**provisioner 구성** (순서 중요):
1. `update_ubuntu.sh` — apt 업그레이드 + reboot (`expect_disconnect = true` 필수)
2. 30초 대기 (`pause_before = "30s"`) — VM 재부팅 완료 대기
3. 나머지 스크립트 일괄 실행
4. inline zero-fill — `dd if=/dev/zero` (minimize.sh가 QEMU에서 skip되므로 필수)

---

## 2. arm64 빌드 (로컬 Mac M-series)

### 사전 준비

```
ISO 위치: /Users/hj/Documents/vagrant_cloud/iso/ubuntu-24.04.4-live-server-arm64.iso
VirtualBox: 7.1+ (macOS arm64 host 전용)
```

### 빌드 명령

```bash
cd /Users/hj/11.Github/IaC/bento/bento
packer build \
  -only=virtualbox-iso.vm \
  -var-file=os_pkrvars/ubuntu/ubuntu-24.04-aarch64.pkrvars.hcl \
  packer_templates/
```

### 빌드 결과 → 보관 및 업로드

```bash
# 1. 결과물 버전 네이밍 후 보관
VERSION=1.0.1  # 예시
mv builds/ubuntu-24.04-aarch64.virtualbox.box \
   /Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v${VERSION}.box

# 2. HCP 토큰 획득
TOKEN=$(curl -sf \
  --request POST \
  --url "https://auth.idp.hashicorp.com/oauth2/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "client_id=<HCP_CLIENT_ID>&client_secret=<HCP_CLIENT_SECRET>&grant_type=client_credentials&audience=https://api.hashicorp.cloud" \
  | jq -r '.access_token')

# 3. Vagrant Cloud 업로드
VAGRANT_CLOUD_TOKEN=$TOKEN vagrant cloud publish \
  sysnet4admin/Ubuntu-k8s \
  ${VERSION} \
  virtualbox \
  /Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v${VERSION}.box \
  --architecture arm64 \
  --release --force
```

### GitHub Actions에서 arm64를 빌드할 수 없는 이유

- VirtualBox 7.1의 arm64 지원은 **macOS arm64 host 전용**
- GitHub `ubuntu-24.04-arm` runner는 Linux arm64 — VirtualBox 패키지 없음
- QEMU/KVM arm64 템플릿 미구현 (필요 시 추가 가능)

---

## 3. 공통 사항

### provisioning 스크립트 실행 순서

| 순서 | 스크립트 | x86_64 | arm64 | 비고 |
|---|---|---|---|---|
| 0 | `custom_pre_hoon.sh` | X | O | DNS 8.8.8.8 (빌드 중 네트워크 안정화) |
| 1 | `update_ubuntu.sh` | O | O | reboot 포함 |
| 2 | `networking_ubuntu.sh` | O | O | |
| 3 | `sudoers_ubuntu.sh` | O | O | |
| 4 | `sshd.sh` | O | O | |
| 5 | `vagrant.sh` | O | O | |
| 6 | `systemd_ubuntu.sh` | O | O | |
| 7 | `cleanup_ubuntu.sh` | O | O | |
| 8 | `custom_post_hoon.sh` | O | O | 커스텀 패키지/설정 |
| 9 | `minimize.sh` | X (exit 0) | O | QEMU에서 no-op |
| 10 | inline zero-fill | O | X | minimize.sh 대체 |
| - | `motd.sh` | X | O (빈 스크립트) | bento 배너 비활성화 |

### custom_post_hoon.sh 설치 내용

- root SSH 활성화 (비밀번호: vagrant)
- `sshd.service` symlink (Ubuntu 24.04 호환성)
- 타임존: Asia/Seoul (KST)
- 패키지: zip, jq, bpytop, stress, psmisc, net-tools, bash-completion, sshpass, yq
- 자동 업데이트 비활성화
- IPv6 비활성화
- apt 캐시/로그 정리 (box 용량 최적화)

### Vagrant Cloud 업로드 구조

```
sysnet4admin/Ubuntu-k8s
└── vX.X.X
    ├── virtualbox / arm64  (default_architecture: true)  ← arm64 수동 업로드
    └── virtualbox / amd64                                ← GitHub Actions 자동 업로드
```

같은 버전/프로바이더 내에서 architecture로 분리됨. Vagrant가 호스트 아키텍처에 맞게 자동 선택.

> **주의**: `vagrant cloud publish` 시 `--architecture` 를 반드시 명시해야 함.  
> 빠뜨리면 기존 다른 아키텍처 항목을 덮어쓸 수 있음.

---

## 4. 버전 이력

### sysnet4admin/Ubuntu-k8s-2404-test (x86_64 테스트 박스)

| 버전 | 날짜 | 용량 | 상태 | 비고 |
|---|---|---|---|---|
| v0.0.1 | 2026-04-01 | 2.3GB | import 가능 | zero-fill 없음, OVF 정상 |
| v0.0.2 | 2026-04-02 | 888MB | import 불가 | streamOptimized 추가, OVF 파일명 오류 |
| v0.0.3 | 2026-04-02 | 1.01GB | import 불가 | gzip -9, OVF 파일명 오류 |
| v0.0.4 | 2026-04-02 | — | 빌드 실패 | streamOptimized 제거 → runner 죽음 |
| v0.0.5 | 2026-04-03 | 966MB | import 불가 | OVF 파일명 오류 |
| v0.0.6 | 2026-04-03 | 885MB | import 불가 | OVF 파일명 오류 |
| v0.0.7 | 2026-04-03 | ~900MB | ✅ 동작 확인 | OVF rename 수정 (box.ovf / box-disk001.vmdk) |

### sysnet4admin/Ubuntu-k8s (프로덕션)

| 버전 | 날짜 | 아키텍처 | 용량 | 상태 |
|---|---|---|---|---|
| v0.8.6 | 2025-06-20 | arm64 | 835MB | Ubuntu 22.04 (구버전) |
| v1.0.0 | 2026-04-04 | arm64 | 924MB | ✅ Ubuntu 24.04, 클러스터 테스트 통과 |
| v1.0.0 | 2026-04-07 | amd64 | ~900MB | ✅ Ubuntu 24.04, vagrant up 테스트 통과 |

---

## 5. 시행착오 기록

### x86_64: VirtualBox 빌더 시도 (8회+ 전부 실패)

**근본 원인**: GitHub Actions는 이미 KVM이 활성화된 환경. VirtualBox는 KVM과 하드웨어 가상화를 동시 점유 불가 → QEMU/KVM으로 전환.

### x86_64: QEMU/KVM 전환 후 해결한 이슈

| 이슈 | 원인 | 해결 |
|---|---|---|
| `Qemu failed to start` | /dev/kvm 접근 권한 | `sudo chmod 666 /dev/kvm` |
| SSH disconnect (exit 2300218) | update_ubuntu.sh의 reboot | provisioner 분리 + `expect_disconnect = true` |
| 재부팅 후 SSH 연결 실패 | VM 부팅 미완료 | `pause_before = "30s"` |
| Box 용량 2.3GB | minimize.sh skip + 비압축 VMDK | zero-fill + streamOptimized |
| runner 디스크/메모리 소진 | zero-fill만 적용, streamOptimized 없음 | 반드시 세트로 사용 |
| box import 실패 (v0.0.2~v0.0.6) | OVF 파일명 불일치 (`*.ovf` ≠ `box.ovf`) | tar 추출 후 명시적 rename + OVF 내부 참조 sed 수정 |
| arm64/amd64 덮어쓰기 위험 | `--architecture` 플래그 누락 | `--architecture amd64` / `arm64` 반드시 명시 |

---

## 6. v1.0.0 arm64 클러스터 테스트 결과 (2026-04-04)

**환경**: SSF Vagrantfile, Kubernetes 1.35.1 / Containerd 2.2.1 / Calico v3.31.2

| 테스트 항목 | 결과 |
|---|---|
| 노드 4/4 Ready (cp + w1~w3) | ✅ |
| Deployment (nginx 3, httpd 2, tomcat 1) | ✅ Running, 3개 워커 분산 |
| LoadBalancer — MetalLB (192.168.1.11) | ✅ nginx 응답 정상 |
| ClusterIP (httpd) | ✅ |
| NodePort (tomcat:31530) | ✅ |
| DaemonSet (busybox, 3/3 노드) | ✅ |
| StatefulSet (redis 2개) | ✅ PONG 응답 |
| Job (perl pi 100자리) | ✅ 완료 |
| Cross-node Pod 통신 (Calico) | ✅ |
| DNS (`httpd.default.svc.cluster.local`) | ✅ |

---

## 7. upstream bento 동기화 시 주의

`update_bento_repo_w_custom.sh` 실행 시 아래 파일 자동 보존:

| 파일 | 이유 |
|---|---|
| `scripts/custom_pre_hoon.sh` | DNS 설정 |
| `scripts/custom_post_hoon.sh` | 커스텀 패키지/설정 |
| `scripts/_common/motd.sh` | bento 배너 비활성화 (빈 스크립트) |
| `os_pkrvars/ubuntu/ubuntu-24.04-aarch64.pkrvars.hcl` | 로컬 ISO 경로 등 커스텀 |
| `packer_templates/pkr-builder.pkr.hcl` | 스크립트 순서 커스텀 |

QEMU 템플릿(`bento/ubuntu-24.04-x86_64-qemu.pkr.hcl`)은 bento upstream과 무관하게 관리.
