#!/bin/sh -eux

# add google dns server to avoid dns query error 
cat <<EOF >/etc/resolv.conf;
nameserver 8.8.8.8
EOF

# enable root & ssh connection 
echo 'root:vagrant' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# time zone from utc-0 to kst 
timedatectl set-timezone Asia/Seoul

# install pkgs 
apt-get update 
apt-get install -y zip jq bpytop stress psmisc net-tools
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq


# vimrc last cursor 
cat <<EOF >/root/.vimrc
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
EOF 

# disable Automatic Updates on Ubuntu
cat <<EOF >/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::Update-Package-Lists "0";
EOF

# disable IPV6 on Ubuntu (adding to sysctl)
cat <<EOF >>/etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF