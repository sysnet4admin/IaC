#Main_Source_From: 
# - https://github.com/johanhaleby/kubetail

# usage: 
# 1. Create 
# - bash <(curl -s  https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/kubetail.sh) 

curl -O https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
chmod 755 kubetail
mv ~/kubetail /usr/local/bin
echo "kubetail install successfully"
