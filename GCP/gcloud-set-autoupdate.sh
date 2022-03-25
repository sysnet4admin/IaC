#!/usr/bin/env bash

#####
# usage: 
# curl https://raw.githubusercontent.com/sysnet4admin/IaC/master/GCP/gcloud-set-autoupdate.sh | bash

case $SHELL in
*/zsh) 
  {
    echo '# gcloud components update automatically'
    echo 'gcloud components update -q'
  } >> ~/.zshrc
  echo 'Successfully add to ~/.zshrc'
  ;;
*/bash)
  {
    echo '# gcloud components update automatically'
    echo 'gcloud components update -q'
  } >> ~/.bashrc
  echo 'Successfully add to ~/.bashrc'
  ;;
*)
  echo "NOT Support $SHELL"
esac


