#!/bin/bash
# Steve Ward: 2016-03-09

# USAGE: bash /home/steve/templates/delete-vhost.sh <domain>

# Source: https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts

if [ "$1" == "" ]; then
    echo 'ERROR: No virtual host name was specified.'
    exit 1
fi

DIRECTORY="/var/www/$1/public_html/"

if [ ! -d "$DIRECTORY" ]; then
  	echo "ERROR: The directory "${DIRECTORY}" doesn't exist."
    exit 1
fi

sudo a2dissite "$1".conf
sudo rm /etc/apache2/sites-available/"$1".conf
sudo rm -rf /var/www/"$1"
#sudo rm /etc/ssl/certs/"$1".crt
#sudo rm /etc/ssl/private/"$1".key
sudo systemctl restart apache2
