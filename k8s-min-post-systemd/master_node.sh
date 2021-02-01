#!/usr/bin/env bash

# init kubernetes 
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# raw_address for gitcontent
raw_git="raw.githubusercontent.com/sysnet4admin/IaC/master/manifests" 

# config for kubernetes's network 
kubectl apply -f https://$raw_git/172.16_net_calico_v1.yaml

# install bash-completion for kubectl 
yum install bash-completion -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# extra config: 
# cgroupdriver change from cgroupfs to systemd 
sed -i "s,-H fd:// --containerd=/run/containerd/containerd.sock,--exec-opt native.cgroupdriver=systemd,g" /usr/lib/systemd/system/docker.service
sed -i 's,--n,--cgroup-driver=systemd --n,g' /var/lib/kubelet/kubeadm-flags.env # for 1.20
# sed -i 's,cgroupfs,systemd,g' /var/lib/kubelet/kubeadm-flags.env # 1.18 or previous version
# apply systemd 
systemctl daemon-reload && systemctl restart docker
