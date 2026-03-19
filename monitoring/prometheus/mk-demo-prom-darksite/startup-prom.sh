#!/usr/bin/env bash

# startup minikube
minikube start --driver=none
echo "Wait for minikube boot up properly...in few seconds"
echo "==================================================="
echo ""; sleep 10 

# deploy prometheus
install prometheus prometheus-community/prometheus

kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-np
minikube service prometheus-server-np
kubectl patch service prometheus-server-np --namespace=default \
   --type='json' \
   --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30000}]'

echo ""
echo "promehtues's graph: http://192.168.1.231:300000"
