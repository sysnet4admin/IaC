#!/usr/bin/env bash

cd ~
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.16.1 TARGET_ARCH=x86_64 sh -
cd istio-1.16.1
cp bin/istioctl /usr/local/bin

