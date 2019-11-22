#! /usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker 
yum install docker-ce-18.09.9-3.el7 docker-ce-cli-18.09.9-3.el7 containerd.io-1.2.6-3.3.el7 -y
systemctl enable --now docker

# install kubernetes
yum install kubelet-1.16.3-0 kubeadm-1.16.3-0 kubectl-1.16.3-0 -y 
systemctl enable --now kubelet

