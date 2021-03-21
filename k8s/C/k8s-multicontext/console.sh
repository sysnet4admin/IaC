#!/usr/bin/env bash

# vagrant_home_k8s_config 
va_k8s_cfg="/home/vagrant/.kube/config" 

# install util packages 
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y
yum install sshpass -y

# add kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# install kubectl
yum install kubectl-$1 -y 

# install bash-completion for kubectl 
yum install bash-completion -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> /home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc

# create .kube_config dir
sudo -u vagrant mkdir /home/vagrant/.kube

# copy kubeconfig by sshpass
sudo -u vagrant sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$2:/root/.kube/config $va_k8s_cfg-$2
sudo -u vagrant sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$3:/root/.kube/config $va_k8s_cfg-$3
sudo -u vagrant sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$4:/root/.kube/config $va_k8s_cfg-$4

# flatten .kube_config 
export KUBECONFIG=$va_k8s_cfg-$2:$va_k8s_cfg-$3:$va_k8s_cfg-$4
kubectl config view --flatten > $va_k8s_cfg 
chown vagrant:vagrant .kube/config
