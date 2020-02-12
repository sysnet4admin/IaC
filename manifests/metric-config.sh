#! /usr/bin/env bash
#usage
#1. bash <(curl -s https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/config-metric.sh) 

# raw_address for gitcontent
raw_git="raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/metrics-server-1.8+" 

kubectl apply -f https://$raw_git/aggregated-metrics-reader.yaml
kubectl apply -f https://$raw_git/auth-delegator.yaml
kubectl apply -f https://$raw_git/auth-reader.yaml
kubectl apply -f https://$raw_git/metrics-apiservice.yaml
kubectl apply -f https://$raw_git/metrics-server-deployment.yaml
kubectl apply -f https://$raw_git/metrics-server-service.yaml
kubectl apply -f https://$raw_git/resource-reader.yaml

echo -e "\n###### Check Metrics-Server Service Status #####\n"
kubectl get service metrics-server -n kube-system

echo -e "\n###### Wait 10Sec for Container creation #####" && sleep 10
echo -e "###### Check Metrics-Server Pod Status #####\n"
kubectl get pods -n kube-system -l k8s-app=metrics-server