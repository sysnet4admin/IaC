#! /usr/bin/env bash
# usage: 
# 1. bash <(curl -s https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/install-kubetail.sh) 

curl -O https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
chmod 744 kubetail
mv kubetail /sbin

echo ""
echo "Example: "
echo "1. kubetail -l component=speaker -n metallb-system"
echo "2. kubetail -l k8s-app=calico-node -n kube-system"
echo "3. kubetail <pod_name_as_default>"