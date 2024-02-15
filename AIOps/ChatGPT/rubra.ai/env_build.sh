#!/usr/bin/env bash
# gpg_keyid 
KEYID="234654DA9A296436"

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab (Rmv blank)
sed -i.bak -r 's/(.+swap.+)/#\1/' /etc/fstab

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab (Rmv blank)
sed -i.bak -r 's/(.+swap.+)/#\1/' /etc/fstab

# add kubernetes repo ONLY for 22.04
#mkdir -p /etc/apt/keyrings
#curl -fsSL \ 
#  https://pkgs.k8s.io/core:/stable:/v$1/deb/Release.key \
#  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $KEYID
gpg --export $KEYID  | sudo tee /etc/apt/trusted.gpg.d/k8s-keyid.gpg

echo \
  "deb [signed-by=/etc/apt/trusted.gpg.d/k8s-keyid.gpg] \
  https://pkgs.k8s.io/core:/stable:/v$1/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

#echo \
#  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
#  https://pkgs.k8s.io/core:/stable:/v$1/deb/ /" \
#  | tee /etc/apt/sources.list.d/kubernetes.list

#echo \
#  "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
#  https://apt.kubernetes.io/ kubernetes-xenial main" \
#  | tee /etc/apt/sources.list.d/kubernetes.list

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


