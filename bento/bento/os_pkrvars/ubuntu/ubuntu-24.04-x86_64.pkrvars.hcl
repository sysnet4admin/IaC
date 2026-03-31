os_name                 = "ubuntu"
os_version              = "24.04"
os_arch                 = "x86_64"
iso_url                 = "https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso"
iso_checksum            = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu_64"
vmware_guest_os_type    = "ubuntu-64"
# VirtualBox NAT 환경에서 게이트웨이(호스트)는 항상 10.0.2.2
# {{.HTTPIP}}는 호스트의 물리 NIC IP를 감지하므로 NAT VM에서 도달 불가
# → 10.0.2.2 고정으로 packer HTTP 서버에 안정적으로 접근 (GitHub Actions 포함)
boot_command            = ["<wait>e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"]
