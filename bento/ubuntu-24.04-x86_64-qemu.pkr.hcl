packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.0.0"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
}

variable "ssh_timeout" {
  type    = string
  default = "60m"
}

source "qemu" "ubuntu24" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  output_directory = "builds/ubuntu-24.04-x86_64-qemu"
  vm_name          = "ubuntu-24.04-amd64.qcow2"

  cpus      = 2
  memory    = 4096
  disk_size = "65536M"

  # GitHub Actions KVM 네이티브 사용 (VirtualBox 불필요)
  accelerator = "kvm"
  headless    = true

  # packer HTTP 서버: QEMU user networking에서 호스트는 10.0.2.2
  # {{.HTTPIP}}가 잘못된 IP를 반환할 경우를 대비해 10.0.2.2 고정
  http_directory = "bento/packer_templates/http"

  boot_wait = "5s"
  boot_command = [
    "<wait>e<wait><down><down><down><end> autoinstall ds=nocloud-net\\;s=http://10.0.2.2:{{.HTTPPort}}/ubuntu/<wait><f10><wait>"
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

  # update_ubuntu.sh 마지막에 reboot 명령이 있음 → VM 재부팅으로 SSH 세션 끊김
  # expect_disconnect = true: 재부팅으로 인한 연결 종료를 정상으로 처리
  provisioner "shell" {
    script            = "bento/packer_templates/scripts/ubuntu/update_ubuntu.sh"
    execute_command   = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    expect_disconnect = true
  }

  # 재부팅 후 VM이 완전히 올라올 때까지 대기 후 나머지 스크립트 실행
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

  # minimize.sh는 QEMU builder에서 skip되므로, 직접 디스크 zero-fill 수행
  # zero-fill → qcow2/vmdk 변환 시 빈 공간이 압축되어 box 용량 대폭 감소
  provisioner "shell" {
    inline = [
      "dd if=/dev/zero of=/tmp/whitespace bs=1M || echo 'dd exit code suppressed'",
      "rm -f /tmp/whitespace",
      "sync"
    ]
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }
}
