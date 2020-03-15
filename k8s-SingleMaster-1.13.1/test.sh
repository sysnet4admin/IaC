#! /usr/bin/env bash

echo "192.168.1.10 m-k8s" > /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done
