#!/usr/bin/env bash

# Ubuntu ONLY to aviod useless message
# body: dpkg-preconfigure: unable to re-open stdin
export DEBIAN_FRONTEND=noninteractive

# add kubernetes repo
apt-get update && apt-get install apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
            https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
      https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# add docker-ce repo
apt-get install -y \
        ca-certificates \
        gnupg \
        lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# update package list 
apt-get update 

# install & enable docker 
apt-get install -y docker-ce=$2 docker-ce-cli=$2 
systemctl enable --now docker

# install kubernetes
# both kubelet and kubectl will install by dependency
# but aim to latest version. so fixed version by manually
apt-get install -y kubectl=$1

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# helm installed
DESIRED_VERSION=v3.10.3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# helm completion on bash-completion dir & alias+
helm completion bash > /etc/bash_completion.d/helm
echo 'alias h=helm' >> ~/.bashrc
echo 'complete -F __start_helm h' >> ~/.bashrc

# install minikube binaries
curl -LO https://storage.googleapis.com/minikube/releases/$3/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# install packages for minikube 
apt-get install -y conntrack # network 

# startup minikube
/usr/local/bin/minikube start --driver=none
