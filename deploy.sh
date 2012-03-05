#!/bin/bash
source include/bash_header.sh

# Usage: ./deploy.sh [host]

set -e

user="$1"
host="$2"

function main {
  print_hdr "Setting up signpost server"
  validate_user;
  validate_host;
  clean_host_info;
  upload_and_execute;
}

function output_usage {
  echo "Usage: $0 ubuntu@dX.signpo.st"
  echo "Example: $0 sebastian d2.signpo.st"
}

function validate_user {
  print_subhdr "Validating user"
  if [[ $user == "" ]]; then
    echo "You need to supply the user remote user!"
    output_usage
    exit 1
  fi
}

function validate_host {
  print_subhdr "Validating hostname"
  if [[ $host == "" ]]; then
    echo "You need to supply the host where signpost is to be deployed!"
    output_usage
    exit 1
  fi
}

function clean_host_info {
  print_subhdr "Removing preexisting host info"
  ssh-keygen -R "${host#*@}" 2> /dev/null
}

function upload_and_execute {
  print_subhdr "Uploading recepies to the server and executing them"
  tar -cf - . | ssh -vv -o 'StrictHostKeyChecking no' "$user@$host" '
  sudo rm -rf ~/chef &&
  mkdir ~/chef &&
  cd ~/chef &&
  tar -xpf - &&
  sudo bash install.sh'
}

main;

