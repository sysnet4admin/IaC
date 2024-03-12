#!/usr/bin/env bash

# config for LocalAI by k8sgpt 
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.27/k8sgpt_amd64.deb
dpkg -i k8sgpt_amd64.deb

# install packages
apt-get install docker-ce docker-ce-cli -y 
apt-get install python3-pip -y 

# alias 
echo 'alias p=python3' >> ~/.bashrc
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

# alias k8sgpt 
echo 'source <(k8sgpt completion bash)' >> ~/.bashrc 

# git clone 
git clone https://github.com/oobabooga/text-generation-webui \
  $HOME/text-generation-webui
find $HOME/text-generation-webui -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# download models 
# cd $HOME/text-generation-webui ; \
# python3 download-model.py TinyLlama/TinyLlama-1.1B-Chat-v1.0

# load text-generation-webui
# $HOME/text-generation-webui/start_linux.sh \
#   --listen --listen-host 0.0.0.0 --listen-port=7861 \
#   --extensions openai --model TinyLlama_TinyLlama-1.1B-Chat-v1.0 \
#   --api-port 5001 <<<"N" &
# echo "Web: 0.0.0.0:7861, API: 0.0.0.0:5001"

# N = NO GPU

cat <<EOF > /usr/local/bin/start_tgw
#!/usr/bin/env bash
$HOME/text-generation-webui/start_linux.sh \
  --listen --listen-host 0.0.0.0 --listen-port=7861 \
  --extensions openai --model TinyLlama_TinyLlama-1.1B-Chat-v1.0 \
  --api-port 5001 &
echo "Web: 0.0.0.0:7861, API: 0.0.0.0:5001"
EOF
chmod 700 /usr/local/bin/start_tgw 

# check command 
# curl http://localhost:5001/v1/models|jq '.data[].id'

#python3 server.py --listen-host 0.0.0.0 --listen \
#  --model google_gemma-2b  --extensions  openai --cpu --loader transformers

# ollam 
# https://github.com/ollama/ollama

# install Ollama 
curl -fsSL https://ollama.com/install.sh | sh

# pull docker image < 5GB 
ollama pull llama2
ollama pull gemma:7b
ollama pull openchat
ollama pull vicuna

# pull docker image < 2GB 
ollama pull gemma:2b
ollama pull phi

# run model by ollama 
ollama run gemma:2b 

# auth add (default: gemma:2b)
k8sgpt auth add -b localai -u http://localhost:11434/v1 --model gemma:7b 


