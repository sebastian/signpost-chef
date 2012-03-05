#! /usr/bin/env bash
set -e

# Remember where the user was when we started
# so we can make sure we end up there again as well!
start_dir=`pwd`

source include/bash_header.sh

function main {
  check_deps;
  header;
  welcome;
  echo
  ask_continue;
  get_info;
  start_real_work;
}

function error_colour {
  COL_ERROR="\x1b[1;31m"
  echo -e -n $COL_ERROR
}

function blue_colour {
  COL_BLUE="\x1b[34;01m"
  echo -e -n $COL_BLUE
}

function yellow_colour {
  COL_YELLOW="\x1b[1;33m"
  echo -e -n $COL_YELLOW
}

function reset_colour {
  COL_RESET="\x1b[39;49;00m"
  echo -e -n $COL_RESET
}

# Created using figlet
function header {
  blue_colour
  echo "     _                             _   "
  echo " ___(_) __ _ _ __  _ __   ___  ___| |_ "
  echo "/ __| |/ _\` | '_ \| '_ \ / _ \/ __| __|"
  echo "\__ \ | (_| | | | | |_) | (_) \__ \ |_ "
  echo "|___/_|\__, |_| |_| .__/ \___/|___/\__|"
  echo "       |___/      |_|                  "
  echo 
  reset_colour
}

function action {
  blue_colour
  echo "                    _   _             _ "
  echo "          __ _  ___| |_(_) ___  _ __ | |"
  echo "         / _\` |/ __| __| |/ _ \| '_ \| |"
  echo " _ _ _  | (_| | (__| |_| | (_) | | | |_|"
  echo "(_|_|_)  \__,_|\___|\__|_|\___/|_| |_(_)"
  echo
  reset_colour
}

function hurray {
  blue_colour
  echo " _                                _ "
  echo "| |__  _   _ _ __ _ __ __ _ _   _| |"
  echo "| '_ \| | | | '__| '__/ _\` | | | | |"
  echo "| | | | |_| | |  | | | (_| | |_| |_|"
  echo "|_| |_|\__,_|_|  |_|  \__,_|\__, (_)"
  echo "                            |___/   "
  echo
  reset_colour
}

function welcome {
  echo "Welcome to the signpost server installation wizard."
  echo 
  echo "For this installation to work, you will need the following:"
  echo "* A domain name"
  echo "* A clean installation of ubuntu"
  echo "* A user account with sudo rights and not requiring password for sudo."
  echo "* Your root domain name server should also point to the server."
}

function check_deps {
  check_for "git"
}

user="sebastian"
signpost_number=2
domain="signpo.st"
external_ip="192.168.56.101"
external_dns="ec2-107-20-47-111.compute-1.amazonaws.com"
iodine_password="FOOBAAR"

fun_return=

function persist_config {
  if [[ -e config.yaml ]]; then
    rm config.yaml
  fi
  touch config.yaml
  echo "config:" >> config.yaml
  echo "  user: $user" >> config.yaml
  echo "  signpost_number: $signpost_number" >> config.yaml
  echo "  domain: $domain" >> config.yaml
  echo "  external_ip: $external_ip" >> config.yaml
  echo "  external_dns: $external_dns" >> config.yaml
  echo "  iodine_password: $iodine_password" >> config.yaml
}

function request_with_default {
  what=$1
  description=$2
  default=$3

  while true; do
    echo 
    echo $description
    yellow_colour
    echo -n "$what "
    reset_colour
    if [[ $default != "" ]]; then
      echo -n "(defaults to '$default')"
    else
      echo -n "[required]"
    fi
    echo -n ": "
    read response

    if [[ $response == *" "* ]]; then
      error_colour
      echo "$what cannot contain spaces"
      reset_colour
    else
      if [[ $response != "" ]]; then
        fun_return=$response
        return 0
      else
        if [[ $default != "" ]]; then
          fun_return=$default
          return 0
        fi
      fi
    fi
  done
}

function get_info {
  echo "Please supply the following information to setup your signpost server."
  echo 
  blue_colour
  echo "Server login information"
  reset_colour

  request_with_default "username" "Username used to log onto the server" $user 
  user=$fun_return

  request_with_default "signpost number" "The number of your signpost domain. Example: for domain 'd2.signpo.st', the number is 2" $signpost_number 
  signpost_number=$fun_return

  request_with_default "domain" "Your domain name, without dN. Example: for domain 'd2.signpo.st', type in 'signpo.st'" $domain
  domain=$fun_return

  request_with_default "external ip" "The external IP of your server" $external_ip 
  external_ip=$fun_return

  request_with_default "external DNS" "An external CNAME for your domain" $external_dns 
  external_dns=$fun_return

  request_with_default "node password" "This is the password used by your other devices to connect to your signpost."
  iodine_password=$fun_return
}

function start_real_work {
  echo
  yellow_colour
  echo "-------------------------"
  echo "| PLEASE READ CAREFULLY |"
  echo "-------------------------"
  reset_colour
  echo
  echo "If you choose to continue, this program will make significant"
  echo "changes to your server. Please note that we do not take"
  echo "responsibility for problems that might arise as a result of the"
  echo "changes."
  echo
  ask_continue;
  echo
  action
  echo "Setup starting now! This will take a while, please be patient."
  get_repo
  persist_config
  ./deploy.sh $user $external_ip
  hurray
  echo "We are done!"
  echo "You should now try adding some clients."
  echo "You do that by: foo bar gazizzle. (GOOD LUCK)."
  echo
  echo
}

function get_repo {
  if [[ -d /tmp/signpost-chef ]]; then
    rm -rf /tmp/signpost-chef
  fi
  git clone https://github.com/sebastian/signpost-chef /tmp/signpost-chef
  cd /tmp/signpost-chef
  echo "Currently in `pwd`"
}

function check_for {
  src=$1;
  whereis=`whereis $src`;
  if [[ $whereis == "" ]]; then
    error_colour;
    echo "This script cannot continue without '$src'. Please install '$src' and try again."
    reset_colour;
    exit 1
  fi
}

main;
