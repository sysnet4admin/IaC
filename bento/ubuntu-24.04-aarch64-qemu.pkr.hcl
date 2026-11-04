# GitHub Actions arm64 러너(ubuntu-24.04-arm)에서 Ubuntu 24.04 aarch64 box를 QEMU로 빌드한다(.github/workflows/build-ubuntu-24.04-arm64.yml).
# 러너에 KVM이 없어 에뮬레이션으로 3시간 19분 걸린다. 기본 빌드는 로컬 Mac이다(BUILD_ARCH_DECISION.md).
# x86_64 템플릿(ubuntu-24.04-x86_64-qemu.pkr.hcl)과 같은 설치 설정과 스크립트를 사용한다.
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.1.0"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.ubuntu.com/ubuntu/releases/24.04.4/release/ubuntu-24.04.4-live-server-arm64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:9a6ce6d7e66c8abed24d24944570a495caca80b3b0007df02818e13829f27f32"
}

# /dev/kvm이 있으면 kvm, host. 없으면 tcg(에뮬레이션), max.
variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "cpu_model" {
  type    = string
  default = "host"
}

variable "efi_firmware_code" {
  type    = string
  default = "/usr/share/AAVMF/AAVMF_CODE.fd"
}

variable "efi_firmware_vars" {
  type    = string
  default = "/usr/share/AAVMF/AAVMF_VARS.fd"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "ssh_timeout" {
  type    = string
  default = "60m"
}

# GRUB 메뉴가 뜨기 전에 키를 보내면 사라진다. 메뉴가 뜰 때까지 <up>을 반복해 30초 자동 부팅을 멈춘 뒤 편집한다.
variable "grub_wait_steps" {
  type    = number
  default = 6
}

locals {
  wait_for_grub = join("", [for i in range(var.grub_wait_steps) : "<wait5><up>"])
}

source "qemu" "ubuntu24" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  output_directory = "builds/ubuntu-24.04-aarch64-qemu"
  vm_name          = "ubuntu-24.04-arm64.qcow2"

  qemu_binary  = "qemu-system-aarch64"
  machine_type = "virt"
  accelerator  = var.accelerator
  cpu_model    = var.cpu_model

  efi_boot          = true
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars

  cpus      = var.cpus
  memory    = 4096
  disk_size = "65536M"

  # virt 머신에는 IDE가 없다. 디스크는 virtio-blk, ISO는 virtio-scsi로 붙인다
  # (둘 다 if=virtio면 index 0이 겹쳐 QEMU가 시작하지 않는다).
  disk_interface  = "virtio"
  cdrom_interface = "virtio-scsi"

  # virt 머신에는 기본 화면과 키보드가 없다. boot_command(VNC)를 보내려면 둘 다 필요하다.
  # -device를 지정하면 플러그인의 기본 -device가 빠진다. ISO용 SCSI 장치는 직접 넣고 virtio-net은 플러그인이 다시 넣는다.
  qemuargs = [
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-cd,bus=scsi0.0,drive=cdrom0"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
    ["-serial", "file:serial-aarch64.log"],
  ]

  headless       = true
  http_directory = "bento/packer_templates/http"

  boot_wait = "5s"
  boot_command = [
    "${local.wait_for_grub}e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"
  ]

  communicator = "ssh"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = var.ssh_timeout

  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
  format           = "qcow2"
}

build {
  sources = ["source.qemu.ubuntu24"]

  provisioner "shell" {
    script            = "bento/packer_templates/scripts/ubuntu/update_ubuntu.sh"
    execute_command   = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before = "30s"
    scripts = [
      "bento/packer_templates/scripts/ubuntu/networking_ubuntu.sh",
      "bento/packer_templates/scripts/ubuntu/sudoers_ubuntu.sh",
      "bento/packer_templates/scripts/_common/sshd.sh",
      "bento/packer_templates/scripts/_common/vagrant.sh",
      "bento/packer_templates/scripts/ubuntu/systemd_ubuntu.sh",
      "bento/packer_templates/scripts/ubuntu/cleanup_ubuntu.sh",
      "bento/packer_templates/scripts/custom_post_hoon.sh",
    ]
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  provisioner "shell" {
    inline = [
      "dd if=/dev/zero of=/tmp/whitespace bs=1M || echo 'dd exit code suppressed'",
      "rm -f /tmp/whitespace",
      "sync"
    ]
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }
}
