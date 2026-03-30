#!/bin/sh -eux
# due to some pkgs and configuration removed by some scripts

# enable root & ssh connection 
echo 'root:vagrant' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# Ubuntu 24.04부터 sshd.service alias가 제거됨 (22.04까지는 ssh.service의 alias로 존재했음)
# provisioning 스크립트에서 'systemctl reload sshd' 등을 그대로 사용할 수 있도록
# 박스 빌드 시점에 symlink를 생성해 호환성 확보
ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/sshd.service 2>/dev/null || true
systemctl daemon-reload

# time zone from utc-0 to kst 
timedatectl set-timezone Asia/Seoul

# install pkgs 
apt-get update 
apt-get install -y zip jq bpytop stress psmisc net-tools bash-completion sshpass
ARCH=$(dpkg --print-architecture)
wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" -O /usr/bin/yq && \
    chmod +x /usr/bin/yq


# vimrc last cursor 
# TBD

# disable Automatic Updates on Ubuntu
cat <<EOF >/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::Update-Package-Lists "0";
EOF

# disable IPV6 on Ubuntu (adding to sysctl)
cat <<EOF >/etc/sysctl.d/99-local-network.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

# optimize box size
apt-get clean && apt-get autoremove -y
truncate -s 0 /var/log/*.log
rm -rf /tmp/* /var/tmp/*
unset HISTFILE && rm -f /root/.bash_history
