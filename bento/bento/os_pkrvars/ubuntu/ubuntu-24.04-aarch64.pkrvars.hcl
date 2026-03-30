os_name                 = "ubuntu"
os_version              = "24.04"
os_arch                 = "aarch64"
iso_url                 = "/Users/hj/Documents/vagrant_cloud/iso/ubuntu-24.04.4-live-server-arm64.iso"
iso_checksum            = "9a6ce6d7e66c8abed24d24944570a495caca80b3b0007df02818e13829f27f32"
parallels_guest_os_type = "ubuntu"
vbox_guest_os_type      = "Ubuntu24_LTS_arm64"
vmware_guest_os_type    = "arm-ubuntu-64"
boot_command            = ["<wait>e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"]
