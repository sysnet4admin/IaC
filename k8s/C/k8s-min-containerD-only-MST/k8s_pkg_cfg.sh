#!/usr/bin/env bash

# install util packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install containerd 
yum install containerd.io-$2 -y

# install kubernetes
# both kubelet and kubectl will install by dependency
# but aim to latest version. so fixed version by manually
yum install kubelet-$1 kubectl-$1 kubeadm-$1 -y 

# containerd configure to  default
containerd config default > /etc/containerd/config.toml

# Fixed container runtime to containerd
cat <<EOF > /etc/default/kubelet
KUBELET_KUBEADM_ARGS=--container-runtime=remote \
                     --container-runtime-endpoint=/run/containerd/containerd.sock \
                     --cgroup-driver=systemd
#KUBELET_EXTRA_ARGS=--node-ip=192.168.1.n
EOF

# Avoid WARN&ERRO(default endpoints) when crictl run  
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

# Ready to install for k8s 
systemctl enable --now containerd
systemctl enable --now kubelet

