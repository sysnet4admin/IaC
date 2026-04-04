# Ubuntu 24.04 Vagrant Box 빌드 가이드 (x86_64 + arm64)

> 최종 업데이트: 2026-04-04
> 목적: Claude Code가 이 문서를 읽고 x86_64/arm64 빌드를 각각 수행할 수 있도록 정리
> Vagrant Cloud: `sysnet4admin/Ubuntu-k8s-2404-test` (테스트), `sysnet4admin/Ubuntu-k8s` (프로덕션)

---

## 현재 상태 (빠른 참조)

| 항목 | x86_64 | arm64 |
|---|---|---|
| **프로덕션 버전** | 미출시 (테스트 중) | **v1.0.0** ✅ |
| **Vagrant Cloud 박스** | `sysnet4admin/Ubuntu-k8s-2404-test` | `sysnet4admin/Ubuntu-k8s` |
| **동작 확인** | v0.0.7 빌드 완료, import 테스트 필요 | v1.0.0 클러스터 테스트 통과 |
| **로컬 box 파일** | — | `/Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v1.0.0.box` |

### x86_64 다음 할 일

1. v0.0.7을 x86_64 머신에서 `vagrant up` 테스트 (box.ovf 패키징 수정 확인)
2. 테스트 통과 시 `sysnet4admin/Ubuntu-k8s`에 `v1.0.0`으로 업로드
3. `PACKER_LOG: 1` 제거 (디버깅 완료)
4. `box_name` 기본값을 `sysnet4admin/Ubuntu-k8s`로 변경

---

## 아키텍처별 빌드 요약

| 항목 | x86_64 | arm64 (aarch64) |
|---|---|---|
| **빌드 환경** | GitHub Actions (`ubuntu-latest`) | 로컬 Mac M-series (수동) |
| **빌더** | QEMU/KVM (전용 템플릿) | VirtualBox (bento upstream 템플릿) |
| **Packer 템플릿** | `bento/ubuntu-24.04-x86_64-qemu.pkr.hcl` | `bento/bento/packer_templates/` + pkrvars |
| **워크플로우** | `.github/workflows/build-ubuntu-24.04.yml` | 없음 (수동) |
| **autoinstall** | HTTP 서버 (`10.0.2.2:PORT`) | HTTP 서버 (`{{.HTTPIP}}:PORT`) |
| **minimize** | inline zero-fill (minimize.sh는 QEMU에서 skip) | `minimize.sh` (VirtualBox용, 정상 동작) |
| **box 압축** | `gzip -9` | `compression_level = 9` (동일) |
| **빌드 시간** | ~14분 | ~9분 |
| **용량** | ~900MB (빌드 시점 패키지마다 다름) | 924MB (v1.0.0) |

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

### 빌드 파이프라인

```
GitHub Actions (ubuntu-latest, 네이티브 KVM)
  ↓ packer build (QEMU/KVM)
ubuntu-24.04-amd64.qcow2
  ↓ inline zero-fill provisioner (dd if=/dev/zero)
  ↓ qemu-img convert -o subformat=streamOptimized
ubuntu-24.04-amd64.vmdk (deflate 압축)
  ↓ VBoxManage createvm → export OVA
  ↓ tar xf → mv *.ovf box.ovf → mv *.vmdk box-disk001.vmdk (Vagrant 규격)
  ↓ tar cf - | gzip -9
ubuntu-24.04-x86_64.virtualbox.box
  ↓ vagrant cloud publish
Vagrant Cloud
```

### 실행 방법

GitHub Actions → "Build Ubuntu 24.04 Vagrant Box" → Run workflow:
- `version`: 업로드할 버전 (예: `1.0.0`)
- `box_name`: `sysnet4admin/Ubuntu-k8s` (프로덕션) 또는 `sysnet4admin/Ubuntu-k8s-2404-test` (테스트)

### QEMU 템플릿 핵심 설정

```hcl
source "qemu" "ubuntu24" {
  accelerator    = "kvm"           # GitHub Actions 네이티브 KVM
  headless       = true
  disk_size      = "65536M"
  http_directory = "bento/packer_templates/http"
  # QEMU user networking에서 호스트는 항상 10.0.2.2
  boot_command   = ["...autoinstall ds=nocloud-net;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/..."]
}
```

**provisioner 구성** (순서 중요):
1. `update_ubuntu.sh` — apt 업데이트 + reboot (`expect_disconnect = true` 필수)
2. 30초 대기 후 나머지 스크립트 일괄 실행 (`pause_before = "30s"`)
3. inline zero-fill — `dd if=/dev/zero` (minimize.sh가 QEMU에서 skip되므로 필수)

### box 패키징 핵심 (v0.0.7에서 수정)

VBoxManage export 결과물 파일명이 `ubuntu-24.04-amd64.ovf`이지만
Vagrant는 반드시 `box.ovf` / `box-disk001.vmdk`를 기대함.
**rename + OVF 내부 참조 갱신이 필수:**

```bash
tar xf ../ubuntu-24.04-amd64.ova
mv *.ovf box.ovf
for f in *.vmdk; do
  sed -i "s|${f}|box-disk001.vmdk|g" box.ovf
  mv "$f" box-disk001.vmdk
done
```

### 용량 최적화 (2.3GB → ~900MB)

`minimize.sh`는 QEMU builder에서 즉시 exit. 두 가지 필수 조치:

1. **inline zero-fill** — 빈 공간을 0으로 채워 압축률 향상
2. **streamOptimized VMDK** — deflate 압축으로 VMDK 자체를 압축
   - ⚠️ streamOptimized 없이 zero-fill만 하면 64GB VMDK로 runner 죽음 (v0.0.4 전례)

### 용량 변동 이유

매 빌드마다 `update_ubuntu.sh`가 `apt-get upgrade` 실행 → 빌드 시점 패키지에 따라 용량 달라짐 (±80MB 수준). 정상 현상.

### GitHub Actions 필수 Secrets

| Secret | 용도 |
|---|---|
| `HCP_CLIENT_ID` | Vagrant Cloud HCP 인증 |
| `HCP_CLIENT_SECRET` | Vagrant Cloud HCP 인증 |
| `GITHUB_TOKEN` | Packer init API rate limit 방지 (자동 제공) |

---

## 2. arm64 빌드 (로컬 Mac M-series)

### 파일 구조

```
IaC/bento/bento/
├── os_pkrvars/ubuntu/
│   └── ubuntu-24.04-aarch64.pkrvars.hcl   # arm64 변수 파일 (로컬 ISO 경로)
├── packer_templates/
│   ├── pkr-sources.pkr.hcl               # VirtualBox-iso 소스 정의
│   ├── pkr-builder.pkr.hcl               # 빌드 정의 (provisioner 순서)
│   ├── http/ubuntu/user-data              # autoinstall 설정
│   └── scripts/                           # provisioning 스크립트 (공용)
└── builds/                                # 빌드 결과물
```

### 사전 준비

1. ISO (로컬):
   ```
   /Users/hj/Documents/vagrant_cloud/iso/ubuntu-24.04.4-live-server-arm64.iso
   ```
2. VirtualBox 7.1+ (macOS arm64 호스트 지원)

### 빌드 명령

```bash
cd /Users/hj/11.Github/IaC/bento/bento
packer build \
  -only=virtualbox-iso.vm \
  -var-file=os_pkrvars/ubuntu/ubuntu-24.04-aarch64.pkrvars.hcl \
  packer_templates/
```

### 빌드 결과 → 저장 위치

```bash
# 빌드 결과
builds/ubuntu-24.04-aarch64.virtualbox.box

# 버전 네이밍 후 보관 위치 (mv로 이동)
/Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v{VERSION}.box
```

**네이밍 규칙**: `ubuntu-{OS버전}-{아키텍처}.{프로바이더}-v{버전}.box`
예: `ubuntu-24.04-aarch64.virtualbox-v1.0.0.box`

### Vagrant Cloud 수동 업로드

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
  sysnet4admin/Ubuntu-k8s \
  <VERSION> virtualbox \
  /Users/hj/Documents/vagrant_cloud/ubuntu-24.04-aarch64.virtualbox-v<VERSION>.box \
  --architecture arm64 \
  --release --force
```

### GitHub Actions에서 arm64를 빌드할 수 없는 이유

- VirtualBox 7.1의 arm64 지원은 **macOS arm64 host 전용**
- GitHub `ubuntu-24.04-arm` runner는 Linux arm64 — VirtualBox 패키지 없음
- QEMU/KVM arm64 runner 빌드는 미검증

---

## 3. 공통 사항

### provisioning 스크립트 실행 순서

| 순서 | 스크립트 | x86_64 | arm64 | 비고 |
|---|---|---|---|---|
| 1 | `update_ubuntu.sh` | O | O | reboot 포함 |
| 2 | `networking_ubuntu.sh` | O | O | |
| 3 | `sudoers_ubuntu.sh` | O | O | |
| 4 | `sshd.sh` | O | O | |
| 5 | `vagrant.sh` | O | O | |
| 6 | `systemd_ubuntu.sh` | O | O | |
| 7 | `cleanup_ubuntu.sh` | O | O | |
| 8 | `custom_post_hoon.sh` | O | O | |
| 9 | `minimize.sh` | X (skip) | O | QEMU에서 exit 0 |
| 10 | inline zero-fill | O | X | minimize.sh 대체 |
| - | `custom_pre_hoon.sh` | X | O | DNS 8.8.8.8 (빌드 중) |
| - | `motd.sh` | X | O (빈 스크립트) | bento 배너 비활성화 |

### custom_post_hoon.sh 설치 내용

- root SSH 활성화 (비밀번호: vagrant)
- `sshd.service` symlink (Ubuntu 24.04 호환성 — 22.04 provisioning 스크립트와 호환)
- 타임존: Asia/Seoul (KST)
- 패키지: zip, jq, bpytop, stress, psmisc, net-tools, bash-completion, sshpass, yq
- 자동 업데이트 비활성화
- IPv6 비활성화
- apt 캐시/로그 정리 (box 용량 최적화)

### arm64 컨테이너 이미지 주의사항

arm64 클러스터에서 multi-arch를 지원하지 않는 이미지는 `exec format error` 발생.
테스트 시 아래 이미지는 arm64 지원 확인됨:
- nginx, httpd, tomcat:11-jre21, redis:7, busybox, perl:5.34

amd64 전용 이미지(일부 fluent/fluentd 등)는 arm64에서 실행 불가.

---

## 4. 시행착오 기록

### x86_64: VirtualBox 빌더 시도 (8회+ 전부 실패)

**증상**: 모든 빌드에서 `Timeout waiting for SSH` — 90분 후 실패

| 시도 | 변경 내용 | 결과 |
|---|---|---|
| 1 | 기본 bento upstream 설정 | SSH 타임아웃 |
| 2 | iptables NAT 규칙 수동 추가 | SSH 타임아웃 |
| 3 | `http_bind_address = "0.0.0.0"` | SSH 타임아웃 |
| 4 | HTTPIP를 `10.0.2.2`로 하드코딩 | SSH 타임아웃 |
| 5 | `boot_wait` 5s → 20s → 60s | SSH 타임아웃 |
| 6 | seed ISO (cidata) 방식 전환 | SSH 타임아웃 |
| 7 | GRUB 키 입력 패턴 변경 | SSH 타임아웃 |
| 8 | boot_command 빈 문자열 + cidata | SSH 타임아웃 |

**근본 원인**: GitHub Actions는 이미 KVM이 활성화된 환경. VirtualBox는 KVM과 하드웨어 가상화를 동시 점유 불가 → QEMU/KVM으로 전환.

### x86_64: QEMU/KVM 전환 후 해결한 이슈

| 이슈 | 원인 | 해결 |
|---|---|---|
| `Qemu failed to start` | /dev/kvm 접근 권한 | `sudo chmod 666 /dev/kvm` |
| SSH disconnect (exit 2300218) | update_ubuntu.sh의 reboot | provisioner 분리 + `expect_disconnect = true` |
| 재부팅 후 SSH 연결 실패 | VM 부팅 미완료 | `pause_before = "30s"` |
| Box 용량 2.3GB | minimize.sh skip + 비압축 VMDK | zero-fill + streamOptimized |
| streamOptimized 없이 zero-fill | runner 디스크/메모리 소진 | streamOptimized 필수 (세트로 사용) |
| box import 실패 (v0.0.2~v0.0.6) | OVF 파일명 불일치 (`*.ovf` ≠ `box.ovf`) | tar 추출 후 명시적 rename + OVF 내부 참조 sed 수정 |

---

## 5. 버전 이력

### sysnet4admin/Ubuntu-k8s-2404-test (x86_64 테스트 박스)

| 버전 | 날짜 | 용량 | 상태 | 비고 |
|---|---|---|---|---|
| v0.0.1 | 2026-04-01 | 2.3GB | import 가능 | zero-fill 없음, OVF 정상 |
| v0.0.2 | 2026-04-02 | 888MB | import 불가 | streamOptimized 추가, OVF 파일명 오류 |
| v0.0.3 | 2026-04-02 | 1.01GB | import 불가 | gzip -9 적용, OVF 파일명 오류 |
| v0.0.4 | 2026-04-02 | — | 빌드 실패 | streamOptimized 제거 → runner 죽음 |
| v0.0.5 | 2026-04-03 | 966MB | import 불가 | v0.0.2 설정 복원, OVF 파일명 오류 |
| v0.0.6 | 2026-04-03 | 885MB | import 불가 | gzip -9, OVF 파일명 오류 |
| v0.0.7 | 2026-04-03 | — | **테스트 필요** | OVF rename 수정 (box.ovf / box-disk001.vmdk) |

### sysnet4admin/Ubuntu-k8s (프로덕션)

| 버전 | 날짜 | 아키텍처 | 용량 | 상태 |
|---|---|---|---|---|
| v0.8.6 | 2025-06-20 | arm64 | 835MB | Ubuntu 22.04 (구버전) |
| **v1.0.0** | 2026-04-04 | arm64 | 924MB | ✅ **Ubuntu 24.04, 클러스터 테스트 통과** |

---

## 6. v1.0.0 arm64 클러스터 테스트 결과 (2026-04-04)

### 환경

- Box: `sysnet4admin/Ubuntu-k8s` v1.0.0
- SSF Vagrantfile: `/Users/hj/11.Github/SSF/Module-1/vanilla-k8s/Vagrantfile`
- Kubernetes: 1.35.1 / Containerd: 2.2.1 / Calico: v3.31.2

### 노드 상태

```
NAME     STATUS   ROLES           VERSION   OS                   KERNEL              CRI
cp-k8s   Ready    control-plane   v1.35.1   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.1
w1-k8s   Ready    <none>          v1.35.1   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.1
w2-k8s   Ready    <none>          v1.35.1   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.1
w3-k8s   Ready    <none>          v1.35.1   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.1
```

### 워크로드 테스트 결과

| 테스트 항목 | 결과 |
|---|---|
| Deployment (nginx 3, httpd 2, tomcat 1) | ✅ Running, 3개 워커에 분산 |
| LoadBalancer — MetalLB (192.168.1.11) | ✅ nginx 응답 정상 |
| ClusterIP (httpd) | ✅ Apache 응답 정상 |
| NodePort (tomcat:31530) | ✅ 서버 응답 정상 |
| DaemonSet (busybox, 3/3 노드) | ✅ 전체 Running |
| StatefulSet (redis 2개) | ✅ Running, PONG 응답 |
| Job (perl pi 계산) | ✅ 완료, 100자리 파이 계산 |
| Cross-node Pod 통신 (Calico) | ✅ w2→w3 nginx 응답 |
| DNS (`httpd.default.svc.cluster.local`) | ✅ 정상 조회 |

---

## 7. upstream bento 동기화 시 주의

`update_bento_repo_w_custom.sh` 실행 시 아래 파일 자동 보존:

| 파일 | 이유 |
|---|---|
| `scripts/custom_pre_hoon.sh` | DNS 설정 |
| `scripts/custom_post_hoon.sh` | 커스텀 패키지/설정 |
| `scripts/_common/motd.sh` | bento 배너 비활성화 (빈 스크립트) |
| `os_pkrvars/ubuntu/ubuntu-24.04-aarch64.pkrvars.hcl` | 로컬 ISO 경로 등 커스텀 |
| `os_pkrvars/ubuntu/ubuntu-24.04-x86_64.pkrvars.hcl` | cidata/boot_command 커스텀 |
| `packer_templates/pkr-builder.pkr.hcl` | 스크립트 순서 커스텀 |

QEMU 템플릿(`bento/ubuntu-24.04-x86_64-qemu.pkr.hcl`)은 bento upstream과 무관하게 관리.
