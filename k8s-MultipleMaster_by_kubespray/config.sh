#! /usr/bin/env bash

# vim configuration 
echo 'alias vi=vim' >> /etc/profile

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# local small dns 
cat <<EOF >  /etc/hosts
192.168.1.11 m11-k8s
192.168.1.12 m12-k8s
192.168.1.13 m13-k8s 
192.168.1.101 w101-k8s
192.168.1.102 w102-k8s
192.168.1.103 w103-k8s 
192.168.1.104 w104-k8s
192.168.1.105 w105-k8s
192.168.1.106 w106-k8s
EOF

# config DNS  
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1
EOF


# authority between all masters and workers
sudo mv auto_pass.sh /root
sudo chmod 744 /root/auto_pass.sh


# it configured (It was configured?)
echo 1 > /proc/sys/net/ipv4/ip_forward