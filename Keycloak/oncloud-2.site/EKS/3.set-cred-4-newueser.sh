#!/usr/bin/env bash

kubectl config set-credentials newuser \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubelogin
