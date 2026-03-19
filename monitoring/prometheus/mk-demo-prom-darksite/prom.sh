#!/usr/bin/env bash

# https://blog.marcnuri.com/prometheus-grafana-setup-minikube
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus

kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-np
minikube service prometheus-server-np
kubectl patch service prometheus-server-np --namespace=default \
   --type='json' \
   --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30000}]'
