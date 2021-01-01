#Main_Source_From: 
# - https://github.com/johanhaleby/kubetail

# usage: 
# 1. Create 
# - bash <(curl -s  https://raw.githubusercontent.com/sysnet4admin/IaC/master/tools/kubetail.sh)

curl -O https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
chmod 755 kubetail
mv ~/kubetail /usr/local/bin
echo "kubetail install successfully"
echo ""
echo "Example: "
echo "1. kubetail -l component=speaker -n metallb-system"
echo "2. kubetail -l k8s-app=calico-node -n kube-system"
echo "3. kubetail <pod_name_as_default>"
