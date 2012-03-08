# Chef recipes for setting up signpost

## Server

Run the following one line command from the terminal on your MacOSX
development machine.
It will SSH into your signpost server and set it up by installing all the
dependencies needed.

    curl -s https://raw.github.com/sebastian/signpost-chef/master/deploy-server.sh > /tmp/sp-install.sh && bash /tmp/sp-install.sh; rm /tmp/sp-install.sh


Prereqs, i.e. you will need the following:

- A clean ubuntu installation
- A user account with passwordless sudo
- Some time
- A domain name pointed at the machine


## Client

Please run the following command from your MacOSX terminal:

    curl -s https://raw.github.com/sebastian/signpost-chef/master/setup-client.rb > /tmp/sp-install-client.rb && ruby /tmp/sp-install-client.rb; rm /tmp/sp-install-client.rb
