#!/usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker 
yum install docker-ce-$2 docker-ce-cli-$2 containerd.io-$3 -y
systemctl enable --now docker

# install kubernetes
# both kubelet and kubectl will install by dependency 
yum install kubeadm-$1 -y 
systemctl enable --now kubelet
