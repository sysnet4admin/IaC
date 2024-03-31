#!/usr/bin/env bash

# init kubernetes 
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
             --pod-network-cidr=172.18.0.0/16 \
             --apiserver-advertise-address=$1

# config for control-plane node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# CNI raw address & config for kubernetes's network 
CNI_ADDR="https://raw.githubusercontent.com/sysnet4admin/IaC/master/k8s/CNI"
kubectl apply -f $CNI_ADDR/172.16_net_calico_v3.26.0.yaml

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl'               >> ~/.bashrc
echo "alias ka='kubectl apply -f'"   >> ~/.bashrc
echo "alias kg-po-ip-stat-no='kubectl get pods -o=custom-columns=\
NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName'" \
                                     >> ~/.bashrc 
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# git clone book source 
git clone https://github.com/internal-k8s/_Book_k8sInfra.git 
mv /home/vagrant/_Book_k8sInfra $HOME
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# make rerepo-Book-k8sInfra and input proper permission
cat <<EOF > /usr/local/bin/rerepo-Book_k8sInfra
#!/usr/bin/env bash
rm -rf $HOME/_Book_k8sInfra
git clone https://github.com/internal-k8s/_Book_k8sInfra.git $HOME/_Book_k8sInfra
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;
EOF
chmod 700 /usr/local/bin/rerepo-Book_k8sInfra
