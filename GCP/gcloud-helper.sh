#!/usr/bin/env bash

#####
# usage: 
# curl https://raw.githubusercontent.com/sysnet4admin/IaC/master/GCP/gcloud-set-autoupdate.sh | bash

[[ -n $DEBUG ]] && set -x
set -eou pipefail
#IFS=$'\n\t'

main() {
  # Check gcloud_conv and install it
  if [[ -f ~/.gcloud_conv ]]; then
    echo "gcloud-helper already installed"
    exit 0
  else 
    curl https://raw.githubusercontent.com/sysnet4admin/IaC/master/GCP/gcloud_conv -o ~/.gcloud_conv
    echo "1.Successfully gcloud_conv added"
  fi

  case $SHELL in
  */zsh) 
    {
      echo '# gcloud components update automatically by HoonJo(SysNet4Admin)'
      echo 'gcloud components update -q'
      echo 'alias g=gcloud'
      echo 'source ~/.gcloud_conv'
    } >> ~/.zshrc
    echo '2.Successfully add to ~/.zshrc'
    ;;
  */bash)
    {
      echo '# gcloud components update automatically by HoonJo(SysNet4Admin)'
      echo 'gcloud components update -q'
      echo 'alias g=gloud'
      echo 'source ~/.gcloud_conv'
    } >> ~/.bashrc
    echo '2.Successfully add to ~/.bashrc'
    ;;
  *)
    echo "NOT Support $SHELL"
  esac
 
  echo "3.Finished to install gcloud-helper"
}

main "$@"
