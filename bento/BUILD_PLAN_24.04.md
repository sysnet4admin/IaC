# Ubuntu 24.04 Vagrant Box 빌드 계획

> 작성일: 2026-03-29
> 목표: Ubuntu 24.04 기반 x86_64 + arm64 듀얼 아키텍처 Vagrant Box 빌드 자동화

---

## 배경

- 현재 `sysnet4admin/Ubuntu-k8s` v0.8.6은 Ubuntu 22.04 기반
- 22.04 Standard 지원 종료: 2027년 5월
- _Book_k8sInfra 교재 출간 전 24.04 전환 필요
- Canonical이 24.04부터 공식 Vagrant Box 배포 중단 (HashiCorp BSL 이슈)
  → 기존처럼 bento 기반 커스텀 빌드 필수

---

## 현재 구조

```
IaC/bento/
├── README.md                          # 22.04 빌드 가이드 (로컬)
├── update_bento_repo_w_custom.sh      # upstream bento 동기화 + 커스텀 복원
└── bento/
    ├── os_pkrvars/ubuntu/
    │   ├── ubuntu-22.04-aarch64.pkrvars.hcl  # 로컬 ISO 경로 (커스텀)
    │   ├── ubuntu-22.04-x86_64.pkrvars.hcl   # 원격 ISO (upstream)
    │   ├── ubuntu-24.04-aarch64.pkrvars.hcl  # 원격 ISO (upstream) ✅ 이미 존재
    │   └── ubuntu-24.04-x86_64.pkrvars.hcl   # 원격 ISO (upstream) ✅ 이미 존재
    └── packer_templates/scripts/
        ├── custom_pre_hoon.sh                # DNS 설정 (8.8.8.8)
        └── custom_post_hoon.sh               # root SSH, KST, 패키지, IPv6 비활성화
```

---

## 수정 사항

### 1. `custom_post_hoon.sh` — yq 아키텍처 분기 (필수)

현재 arm64 하드코딩:
```bash
wget .../yq_linux_arm64 -O /usr/bin/yq
```

변경:
```bash
ARCH=$(dpkg --print-architecture)
wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" -O /usr/bin/yq && \
    chmod +x /usr/bin/yq
```

### 2. `custom_post_hoon.sh` — Box 크기 최적화 추가 (필수)

bento `minimize.sh`는 zero-fill만 처리하므로, 패키지 캐시/로그 정리를 추가해야 함:

```bash
# 패키지 캐시 삭제
apt-get clean && apt-get autoremove -y

# 로그/임시파일 삭제
truncate -s 0 /var/log/*.log
rm -rf /tmp/* /var/tmp/*

# bash history 삭제
unset HISTFILE && rm -f /root/.bash_history
```

### 3. `update_bento_repo_w_custom.sh` — 24.04 pkrvars 백업 목록 추가

24.04 aarch64 pkrvars를 커스텀(로컬 ISO 등)할 경우, 백업/복원 대상에 추가 필요.
원격 ISO를 그대로 사용하면 수정 불필요.

### 4. ISO 버전 업데이트 (필수)

upstream pkrvars가 **24.04.2** ISO를 참조하지만, 현재 최신은 **24.04.4** (2026-02-12).
- 24.04.2 ISO는 `old-releases.ubuntu.com`으로 이동되어 다운로드 실패 가능
- pkrvars의 ISO URL과 **checksum을 24.04.4로 갱신** 필요
- 24.04.2에는 SHA256SUMS에서 live-server-amd64 체크섬 누락 이슈도 보고됨

### 5. autoinstall 검증 강화 대응 (확인 필요)

Ubuntu 24.04에서 autoinstall 검증이 엄격해짐:
- 이전: 인식 안 되는 키 → 경고만
- **24.04: 인식 안 되는 키 → fatal error로 설치 중단**
- bento upstream 24.04 템플릿이 이미 대응했는지 확인 필요 (빌드 테스트 시 검증)

---

## GitHub Actions 워크플로우

### 파일 위치

`IaC/.github/workflows/build-vagrant-box.yml`

### 빌드 전략

| 아키텍처 | Runner | 가상화 | 상태 |
|---|---|---|---|
| x86_64 | `ubuntu-latest` | VirtualBox | chef/bento에서 검증됨 ✅ |
| arm64 | `ubuntu-24.04-arm` | VirtualBox 또는 QEMU/KVM | 테스트 필요 |

> - GitHub Actions `ubuntu-latest`에서 VirtualBox 빌드 **가능 확인** (2024.04~ 중첩 가상화 지원)
> - KVM 모듈 충돌 방지: `sudo rmmod kvm_amd || sudo rmmod kvm_intel || true` 추가 필요
> - arm64가 GitHub Actions에서 안 될 경우 로컬(Apple Silicon Mac) 빌드 유지

### 워크플로우 구조

```yaml
name: Build Vagrant Box (Ubuntu 24.04)

on:
  workflow_dispatch:
    inputs:
      architecture:
        description: 'Target architecture'
        required: true
        type: choice
        options:
          - x86_64
          - arm64
          - both

jobs:
  build-x86_64:
    if: inputs.architecture == 'x86_64' || inputs.architecture == 'both'
    runs-on: ubuntu-latest
    steps:
      # 1. 디스크 공간 확보 (~19GB 추가)
      - uses: jlumbroso/free-disk-space@main

      # 2. 체크아웃
      - uses: actions/checkout@v4

      # 3. Packer + VirtualBox 설치
      # 4. bento build --only=virtualbox-iso.vm (x86_64)
      # 5. .box artifact 업로드
      # 6. Vagrant Cloud 업로드 (HCP 토큰 사용)

  build-arm64:
    if: inputs.architecture == 'arm64' || inputs.architecture == 'both'
    runs-on: ubuntu-24.04-arm
    steps:
      # arm64 빌드 (VirtualBox/QEMU 테스트 후 확정)
```

### Vagrant Cloud 업로드

GitHub Secrets 등록 완료:
- `HCP_CLIENT_ID`: `vagrant-box-builder-022058@baf567ab-...`
- `HCP_CLIENT_SECRET`: (등록됨)

```yaml
- name: Get HCP Token
  run: |
    export VAGRANT_CLOUD_TOKEN=$(curl -s \
      --data "client_id=${{ secrets.HCP_CLIENT_ID }}&client_secret=${{ secrets.HCP_CLIENT_SECRET }}&grant_type=client_credentials" \
      https://auth.idp.hashicorp.com/oauth2/token | jq -r .access_token)

- name: Upload to Vagrant Cloud
  run: |
    vagrant cloud publish sysnet4admin/Ubuntu-k8s \
      <VERSION> virtualbox <BOX_FILE> \
      --architecture <ARCH> \
      --force --release
```

---

## 진행 순서

- [ ] **Step 1**: `custom_post_hoon.sh` 수정 (yq 아키텍처 분기 + 캐시 삭제 최적화)
- [ ] **Step 2**: ISO 버전 확인 (pkrvars가 24.04.4를 참조하는지, checksum 갱신)
- [ ] **Step 3**: x86_64 워크플로우 작성 (`build-vagrant-box.yml`)
- [ ] **Step 4**: **테스트용 Box 이름**으로 x86_64 빌드 + Vagrant Cloud 업로드 테스트
- [ ] **Step 5**: arm64 GitHub Actions runner 테스트 (VirtualBox/QEMU 동작 확인)
- [ ] **Step 6**: arm64 빌드 성공 시 워크플로우에 통합, 실패 시 로컬 유지
- [ ] **Step 7**: 빌드된 Box에서 `uname -r` 확인 (6.8.0-58 이상)
- [ ] **Step 8**: `sysnet4admin/Ubuntu-k8s` v1.0.0 릴리스 (24.04 기반, virtualbox only)

---

## Ubuntu 24.04 전환 시 주의사항

교재 실습 환경에 영향을 주는 커뮤니티 보고 이슈:

| 이슈 | 영향도 | 해결책 |
|---|---|---|
| kube-proxy CrashLoopBackOff (커널 6.8.0-56~57) | ~~Critical~~ 해소 | 6.8.0-58에서 수정됨. 현시점 ISO로 빌드하면 수정된 커널 포함. 빌드 후 `uname -r`로 확인만 |
| AppArmor 강화 → Cilium Init 실패 | High | Cilium 1.16+ 사용 |
| Calico VXLAN 멀티 인터페이스 문제 | High | `IP_AUTODETECTION_METHOD=interface=eth1` 명시 |
| Netplan → VM 동일 IP (10.0.2.15) | High | kubelet `--node-ip` 명시 |
| systemd-resolved + CoreDNS DNS 루프 | Medium | kubeadm 자동 처리, 간헐적 실패 모니터링 |

---

## 참고

- [chef/bento GitHub](https://github.com/chef/bento) — upstream 빌드 워크플로우 참조
- [chef/bento CI: pkr-bld-virtualbox-x64.yml](https://github.com/chef/bento/blob/main/.github/workflows/pkr-bld-virtualbox-x64.yml)
- [HCP Vagrant 인증 가이드](https://developer.hashicorp.com/vagrant/vagrant-cloud/users/authentication)
- [jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space) — GitHub Actions 디스크 확보
