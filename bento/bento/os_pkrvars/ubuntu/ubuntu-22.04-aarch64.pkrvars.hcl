os_name                 = "ubuntu"
os_version              = "22.04"
os_arch                 = "aarch64"
iso_url                 = "/Users/hj/Documents/vagrant_cloud/iso/ubuntu-22.04.5-live-server-arm64.iso"
iso_checksum            = "eafec62cfe760c30cac43f446463e628fada468c2de2f14e0e2bc27295187505"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu_arm64"
vmware_guest_os_type    = "arm-ubuntu-64"
boot_command            = ["<wait>e<wait><down><down><down><end><wait> autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/<f10><wait>"]
