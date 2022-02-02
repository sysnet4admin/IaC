1

# rook-ceph quickstart
# https://rook.io/docs/rook/v1.8/quickstart.html
cd $HOME ; git clone --single-branch --branch v1.8.3 https://github.com/rook/rook.git

cat <<EOF > $HOME/rook-ceph-installer.sh
cd $HOME/rook/deploy/examples
kubectl creeate -f crds.yaml -f common.yaml -f operator.yaml

echo "clsuter will be installed"
sleep 3 ; kubectl create -f cluster.yaml

echo "ceph-toolbox will be installed"
# https://rook.io/docs/rook/v1.8/ceph-toolbox.html
sleep 6 kubectl create -f toolbox.yaml

# Check properly on 
while [ "kubectl get pod -n rook-ceph | wc -l" <= 12 ]; do
    echo "still in deploying cluster"
    sleep 30 
done
EOF
