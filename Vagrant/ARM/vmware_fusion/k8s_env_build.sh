#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab (Rmv blank)
sed -i.bak -r 's/(.+swap.+)/#\1/' /etc/fstab

# add kubernetes repo 
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# add docker-ce repo with containerd
apt-get update && apt-get install gnupg lsb-release
curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# packets traversing the bridge are processed by iptables for filtering
echo 1 > /proc/sys/net/ipv4/ip_forward
# enable br_filter for iptables 
modprobe br_netfilter

# local small dns & vagrant cannot parse and delivery shell code.
echo "127.0.0.1 localhost" > /etc/hosts # localhost name will use by calico-node
echo "$1 cp-k8s" >> /etc/hosts
for (( i=1; i<=$2; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done
