#!/usr/bin/env bash

# Ubuntu ONLY to aviod useless message 
# body: dpkg-preconfigure: unable to re-open stdin
export DEBIAN_FRONTEND=noninteractive

# install util packages 
apt-get install sshpass

# add kubernetes repo
apt-get update && apt-get install -y apt-transport-https ca-certificates curl

curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

# add docker-ce repo 
apt-get install -y gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# update repo info 
apt-get update 
# install kubectl and fixed ver
apt-get install -y kubectl=$1 
apt-mark hold kubelet

# install & enable docker 
apt-get install -y docker-ce=$2 docker-ce-cli=$2 
systemctl enable --now docker

# kubectl completion on bash-completion dir due to completion already installed 
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo "alias ka='kubectl apply -f'" >> ~/.bashrc
echo "alias kd='kubectl delete -f'" >> ~/.bashrc
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

# plugin 
## fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
## kubectx
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
## kube-ps1
git clone https://github.com/jonmosco/kube-ps1.git /opt/kube-ps1
cat <<EOF >>  ~/.bashrc 

#kube-ps1 
source /opt/kube-ps1/kube-ps1.sh
PS1='[\u@\h \W \$(kube_ps1)]\$ '
EOF

# Exceptional config to recall bashrc(i.e. kube-ps1 and other)
echo 'source ~/.bashrc' >> ~/.bash_profile 

