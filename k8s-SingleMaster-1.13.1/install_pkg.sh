#! /usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker 
yum install docker -y && systemctl enable --now docker

# install kubernetes and kubectl will install only master node 
if [ $1 = 'install_kubectl' ]; then
  yum install kubectl-1.16.3-0 -y
fi
yum install kubelet-1.16.3-0 kubeadm-1.16.3-0 -y 
systemctl enable --now kubelet