#! /usr/bin/env bash

# install packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker 
yum install docker -y && systemctl enable --now docker

# install kubernetes
yum install kubelet-1.16.3-0 kubeadm-1.16.3-0 kubectl-1.16.3-0 -y 
systemctl enable --now kubelet