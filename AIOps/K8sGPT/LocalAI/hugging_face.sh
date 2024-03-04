#!/usr/bin/env bash

# install packages
apt-get install python3-pip -y 

# init for hugging face 
pip install huggingface_hub
apt-get install git-lfs -y 

# ssh key gen 
ssh-keygen -t ed25519 -C "pagaia@hotmail.com"

# https://huggingface.co/docs/hub/security-git-ssh#add-a-ssh-key-to-your-account
# cat ~/.ssh/id_ed25519.pub
# ssh -T git@hf.co 



