#!/usr/bin/env bash

# install packages
apt-get install python3-pip -y 

# alias 
echo 'alias python=python3' >> ~/.bashrc
# echo "alias ka='kubectl apply -f'" >> ~/.bashrc

# init for hugging face 
pip install huggingface_hub
apt-get install git-lfs -y 

# for huggingface-cli login
git config --global credential.helper store

# ssh key gen 
# ssh-keygen -t ed25519 -C "pagaia@hotmail.com"
# https://huggingface.co/docs/hub/security-git-ssh#add-a-ssh-key-to-your-account
# cat ~/.ssh/id_ed25519.pub
# ssh -T git@hf.co 

# git clone 
git clone https://github.com/oobabooga/text-generation-webui \
  $HOME/text-generation-webui
find $HOME/text-generation-webui -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# download models 
cd $HOME/text-generation-webui ; \
python3 download-model.py TinyLlama/TinyLlama-1.1B-Chat-v1.0

# load text-generation-webui
$HOME/text-generation-webui/start_linux.sh \
  --listen --listen-host 0.0.0.0 --listen-port=7861 <<EOF
N
EOF &
echo "Open: 0.0.0.0:7861"

# N = NO GPU

