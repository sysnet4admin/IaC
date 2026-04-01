os_name                 = "ubuntu"
os_version              = "24.04"
os_arch                 = "x86_64"
iso_url                 = "https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso"
iso_checksum            = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu_64"
vmware_guest_os_type    = "ubuntu-64"
# [GitHub Actions 대응] seed ISO(cidata) 방식으로 변경
# - 기존 HTTP 방식(ds=nocloud-net;s=http://HTTPIP:PORT/)은 GitHub Actions VirtualBox NAT 환경에서
#   packer HTTP 서버가 VM에서 접근 불가하여 autoinstall이 시작조차 안 됨
# - cd_files로 user-data/meta-data를 cidata 레이블 CD-ROM에 번들 →
#   cloud-init이 HTTP 없이 CD-ROM에서 직접 user-data를 읽음
# - boot_command에서 HTTP URL 제거, autoinstall 키워드만 커널 파라미터에 추가
# - arm64(ubuntu-24.04-aarch64.pkrvars.hcl)는 로컬 Mac에서만 빌드하므로 HTTP 방식 유지
#   → 추후 GitHub Actions 전환 시 이 파일과 동일하게 수정 필요
cd_files                = ["packer_templates/http/ubuntu/user-data", "packer_templates/http/ubuntu/meta-data"]
# x86_64 GRUB 엔트리(blank line 없음): <down><down>으로 linux 줄 도달
# arm64는 blank line 있어 <down><down><down> 필요 → 아키텍처별 GRUB 구조 다름
# ds=nocloud: cidata CD-ROM에서 user-data 읽도록 명시 (seed ISO 방식)
boot_command            = ["<wait>e<wait><down><down><end> autoinstall ds=nocloud<wait><f10><wait>"]
