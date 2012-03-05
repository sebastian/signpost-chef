# Chef recipes for setting up signpost servers

Use the following oneliner to setup a signpost server:

    curl -s https://raw.github.com/sebastian/signpost-chef/master/deploy-server.sh > /tmp/sp-install.sh && bash /tmp/sp-install.sh; rm /tmp/sp-install.sh

Prereqs, i.e. you will need the following:

- A clean ubuntu installation
- A user account with passwordless sudo
- Some time
- A domain name pointed at the machine
