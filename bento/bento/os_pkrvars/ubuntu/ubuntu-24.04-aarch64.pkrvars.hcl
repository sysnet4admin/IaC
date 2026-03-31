os_name                 = "ubuntu"
os_version              = "24.04"
os_arch                 = "aarch64"
iso_url                 = "/Users/hj/Documents/vagrant_cloud/iso/ubuntu-24.04.4-live-server-arm64.iso"
iso_checksum            = "9a6ce6d7e66c8abed24d24944570a495caca80b3b0007df02818e13829f27f32"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu24_LTS_arm64"
vmware_guest_os_type    = "arm-ubuntu-64"
# 로컬 Mac M-series 빌드 전용: {{.HTTPIP}}는 Mac의 VirtualBox 인터페이스 IP를 감지하므로 정상 동작
# GitHub Actions(ubuntu-latest arm runner)는 VirtualBox Linux arm64 미지원으로 사용 불가
# 추후 GitHub Actions에서 빌드 가능해질 경우 x86_64와 동일하게 10.0.2.2로 변경 필요
boot_command            = ["<wait>e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"]
