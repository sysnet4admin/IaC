#!/bin/sh -eux
# due to some pkgs and configuration removed by some scripts

# enable root & ssh connection 
echo 'root:vagrant' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# time zone from utc-0 to kst 
timedatectl set-timezone Asia/Seoul

# install pkgs 
apt-get update 
apt-get install -y zip jq bpytop stress psmisc net-tools bash-completion sshpass
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64 -O /usr/bin/yq &&\
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
