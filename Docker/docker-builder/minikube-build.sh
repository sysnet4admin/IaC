#!/usr/bin/env bash

# kubernetes repo
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# install kubectl only 
yum install kubectl-$1 -y 

# install bash-completion for kubectl 
yum install bash-completion -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# install minikube binaries
curl -LO https://storage.googleapis.com/minikube/releases/v1.23.2/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# install packages for minikube 
yum -y install conntrack # network 

# startup minikube
/usr/local/bin/minikube start --driver=none
