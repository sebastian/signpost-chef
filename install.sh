#!/bin/bash

# This runs as root on the server

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    # aptitude update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install Ruby and Chef
    sudo apt-get install -y ruby1.9.1 ruby1.9.1-dev make &&
    sudo gem1.9.1 install --no-rdoc --no-ri chef --version 0.10.0
fi &&

# Copy our config to a place where we can get at it
cp config.yaml /tmp/config.yaml

# Run Chef :) mmm... smells good!
/usr/bin/env chef-solo -c solo.rb -j solo.json

# Remove config file, because it contains the password, and stuff
# rm /tmp/config.yaml

# Remove chef repo
# rm -rf ~/chef
