#!/usr/bin/env bash

mkdir -p ~/istio-1.16.1/MSA
cd ~/istio-1.16.1/MSA
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git online-boutique
kubectl apply -f ./release/kubernetes-manifests.yaml -n online-boutique

