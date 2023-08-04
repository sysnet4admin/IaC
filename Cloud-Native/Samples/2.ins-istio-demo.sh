#!/usr/bin/env bash

istioctl install --set profile=demo -y
kubectl create ns online-boutique
kubectl label namespace online-boutique istio-injection=enabled

