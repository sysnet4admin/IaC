#!/usr/bin/env bash

# declare CSP (changeable) 
# if you want to register other, it should be in source like hashicorp/aws 
# or manually configure
declare -a CSP=("aws" "azurerm" "google")

# declare t7m default version (from Vagrantfile)
declare -x TERRAFORM_DEFAULT=$1

# update package list 
apt-get update 

# install util packages
apt-get install git
apt-get install unzip  # tfenv's requirement 

## gitignore 
touch ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
{
    echo '.envrc'
    echo '.direnv'
    echo '.vagrant'
} >> ~/.gitignore_global

# terraform utility 
apt-get install direnv

## setup direnv 
echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile   # .bashrc doesn't work 

## direnv - .envrc for each provider  
for i in "${!CSP[@]}"; do
mkdir -p ~/t7m/"${CSP[i]}" # each of CSP's folder 
cat <<EOF > ~/t7m/"${CSP[i]}"/.envrc
export ${CSP[i]}_ACCESS_KEY_ID=ACCOUNT_X_ACCESS_KEY
export ${CSP[i]}_SECRET_ACCESS_KEY=ACCOUNT_X_SECRET_KEY
export ${CSP[i]}_DEFAULT_REGION=ap-east-2
EOF
direnv allow ~/t7m/"${CSP[i]}"             # highly carefurelly use it 
done

## setup tfenv 
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
ln -s ~/.tfenv/bin/* /usr/local/bin


# setup terraform & use
tfenv install ${TERRAFORM_DEFAULT}
tfenv use ${TERRAFORM_DEFAULT}

# init terraform 
for i in "${!CSP[@]}"; do
  echo "provider ${CSP[i]} { }" > ~/t7m/"${CSP[i]}"/init.tf 
  cd ~/t7m/"${CSP[i]}" ; terraform init 
done 
