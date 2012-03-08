#!/bin/bash

# This runs as root on the server

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
  export DEBIAN_FRONTEND=noninteractive &&

  # Upgrade headlessly (this is only safe-ish on vanilla systems)
  apt-get -q -o Dpkg::Options::="--force-confnew" \
      --force-yes -fuy dist-upgrade > /dev/null &&
  # Install Ruby and Chef

  echo "--> Installing ruby" &&
  sudo apt-get install -q -y ruby1.9.1 ruby1.9.1-dev make > /dev/null &&
  echo "--> Installing chef" &&
  sudo gem1.9.1 install --no-rdoc --no-ri chef --version 0.10.8 > /dev/null
fi &&

# Copy our config to a place where we can get at it
cp ~/chef/config.yaml /tmp/config.yaml &&

# Run Chef :) mmm... smells good!
echo "--> Running chef" &&
chef-solo -c solo.rb -j solo-server.json &&

# Remove config file, because it contains the password, and stuff
echo "--> Removing temporary config" &&
rm /tmp/config.yaml &&

# Remove chef repo
echo "--> Removing installation repository" &&
rm -rf ~/chef
