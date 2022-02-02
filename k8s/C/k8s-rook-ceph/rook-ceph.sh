1

# rook-ceph quickstart
# https://rook.io/docs/rook/v1.8/quickstart.html
cd $HOME ; git clone --single-branch --branch v1.8.3 https://github.com/rook/rook.git

cat <<EOF > $HOME/rook-ceph-installer.sh
cd $HOME/rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator.yaml

echo -e "\nclsuter will be installed"
sleep 3 ; kubectl create -f cluster.yaml

echo -e "\nceph-toolbox will be installed"
# https://rook.io/docs/rook/v1.8/ceph-toolbox.html
sleep 6 kubectl create -f toolbox.yaml

# Check properly on 
TOTAL_RC=\$(kubectl get pod -n rook-ceph | tail -n +2 | wc -l)
while [ \$TOTAL_RC -le 33 ]; do
    TOTAL_RC=\$(kubectl get pod -n rook-ceph | tail -n +2 | wc -l)
    echo "still in deploying cluster \$TOTAL_RC/33"
    sleep 30 
done
   echo "\nSuccessfully deployed rook-ceph cluster \$TOTAL_RC/33"
EOF
