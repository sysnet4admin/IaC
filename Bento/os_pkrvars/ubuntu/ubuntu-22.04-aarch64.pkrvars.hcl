os_name                 = "ubuntu"
os_version              = "22.04"
os_arch                 = "aarch64"
iso_url                 = "/Users/hj/Documents/ubuntu-22.04.4-live-server-arm64.iso"
iso_checksum            = "sha256:74b8a9f71288ae0ac79075c2793a0284ef9b9729a3dcf41b693d95d724622b65"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu_64"
vmware_guest_os_type    = "arm-ubuntu-64"
boot_command            = ["<wait>e<wait><down><down><down><end><wait> autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/<f10><wait>"]
