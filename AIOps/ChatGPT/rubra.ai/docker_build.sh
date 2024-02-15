#!/usr/bin/env bash

# install & enable docker
apt-get update
apt-get install docker-ce=$1 docker-ce-cli=$1 -y
systemctl enable --now docker
