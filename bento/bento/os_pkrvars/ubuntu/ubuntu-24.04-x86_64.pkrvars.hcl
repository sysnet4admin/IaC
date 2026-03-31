os_name                 = "ubuntu"
os_version              = "24.04"
os_arch                 = "x86_64"
iso_url                 = "https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso"
iso_checksum            = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu_64"
vmware_guest_os_type    = "ubuntu-64"
# [GitHub Actions 대응] HTTPIP를 10.0.2.2로 고정
# - 기본값 {{.HTTPIP}}는 호스트의 물리 NIC IP(예: Azure eth0)를 감지
# - GitHub Actions의 ubuntu-latest runner에서 VirtualBox NAT VM은
#   물리 NIC IP에 직접 접근 불가 → autoinstall user-data fetch 실패 → SSH timeout
# - VirtualBox NAT에서 호스트(packer HTTP 서버)는 항상 10.0.2.2로 접근 가능
# - 로컬 macOS에서도 VirtualBox NAT 게이트웨이는 동일하게 10.0.2.2이므로 호환됨
# - arm64(ubuntu-24.04-aarch64.pkrvars.hcl)는 로컬 Mac에서만 빌드하므로
#   {{.HTTPIP}} 유지 중 → 추후 GitHub Actions 전환 시 동일하게 수정 필요
boot_command            = ["<wait>e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"]
