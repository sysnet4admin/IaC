#!/usr/bin/env bash

# git clone k8s-code
git clone https://github.com/sysnet4admin/_Lecture_k8s_learning.kit.git $HOME/_Lecture_k8s_learning.kit
find $HOME/_Lecture_k8s_learning.kit -regex ".*\.\(sh\)" -exec chmod 700 {} \;
# remote add 
cd $HOME/_Lecture_k8s_learning.kit
git remote set-url origin git+ssh://git@github.com/sysnet4admin/_Lecture_k8s_learning.kit.git

# git clone IaC
git clone https://github.com/sysnet4admin/IaC.git $HOME/IaC
# remote add
cd $HOME/IaC
git remote set-url origin git+ssh://git@github.com/sysnet4admin/IaC.git

git config --global user.name "Hoon Jo"
git config --global user.email pagaia@hotmail.com

# ssh key gen 
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
echo "***********************"
echo "cat ~/.ssh/id_rsa.pub and put your SSH Keys in github"
