#! /usr/bin/env bash

#Init kubernetes 
kubeadm init --token 123456.1234567890123456 --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.1.10 

#config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#config for kubernetes's network 
kubectl apply -f https://docs.projectcalico.org/master/manifests/calico.yaml