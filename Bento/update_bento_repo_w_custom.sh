#!/usr/bin/env bash

# update bento main to latest 
cd /Users/hj/11.Github/bento
git fetch --all ; git reset --hard origin/main ; git pull origin main

# backup bento custom config
cd /Users/hj/11.Github/IaC/Bento/
cp bento/packer_templates/scripts/custom_pre_hoon.sh /tmp/bento/custom_pre_hoon.sh
cp bento/packer_templates/scripts/custom_post_hoon.sh /tmp/bento/custom_post_hoon.sh
cp bento/os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl /tmp/bento/ubuntu-22.04-aarch64.pkrvars.hcl
cp bento/packer_templates/pkr-builder.pkr.hcl /tmp/bentopkr-builder.pkr.hcl

# update bento directory to latest  
rm -rf bento 
cp -r /Users/hj/11.Github/bento/ ./bento/

# restore bento custom config 
cp /tmp/bento/custom_pre_hoon.sh bento/packer_templates/scripts/custom_pre_hoon.sh 
cp /tmp/bento/custom_post_hoon.sh bento/packer_templates/scripts/custom_post_hoon.sh 
cp /tmp/bento/ubuntu-22.04-aarch64.pkrvars.hcl bento/os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl 
cp /tmp/bentopkr-builder.pkr.hcl bento/packer_templates/pkr-builder.pkr.hcl 
