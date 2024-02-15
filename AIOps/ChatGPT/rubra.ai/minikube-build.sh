#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# install kubectl only 
apt-get install kubectl=$1 -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k
echo 'alias k=kubectl'               >> ~/.bashrc
echo "alias ka='kubectl apply -f'"   >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# install minikube binaries
curl -LO https://github.com/kubernetes/minikube/releases/download/v1.32.0/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# install packages for minikube 
apt-get -y install conntrack # network 

# startup minikube
/usr/local/bin/minikube start --driver=none
