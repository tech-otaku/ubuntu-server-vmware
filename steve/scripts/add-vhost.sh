#!/bin/bash
# Steve Ward: 2019-02-11

# USAGE: add-vhost.sh <domain>
# CODE: /home/steve/scripts/add-vhost.sh

# SOURCE: https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts

clear

# Make sure root is not running this script
if [[ $EUID -eq 0 ]]; then
   echo "ERROR:This script must NOT be run as root." 1>&2
   exit 1
fi

if [ "$1" == "" ]; then
    echo 'ERROR: No virtual host name was specified.'
    exit 1
fi

prefix=""

DIRECTORY="/var/www/$1/public_html"
if [ -d "$DIRECTORY" ]; then
  	echo 'ERROR: The directory '${DIRECTORY}' already exists.'
    exit 1
fi

echo "==================================================================="
echo "Create Virtual Host Script for domain $1"
echo "Installation directory: $DIRECTORY/"
echo "==================================================================="


# Get the port Apache is listening on
#apacheport=`sudo netstat -tlpn | grep apache2 | awk '{print $4}' | grep -o '[0-9]*'`
#read -e -i "$apacheport" -p "> Apache is listening on port: " input
#apacheport="${input:-$apacheport}"

pool="steve"
read -e -i "$pool" -p "> PHP-FPM Pool to use: " input
pool="${input:-$pool}"
echo ""

ssl="Y"
read -e -i "$ssl" -p "> Configure for SSL (Y/n) ? " input
ssl="${input:-$ssl}"

www="n"
read -e -i "$www" -p "> Does this domain have a www prefix (Y/n) ? " input
www="${input:-$www}"

if [[ $www =~ [A-Z] && $www == "Y" ]]; then
	force="n"
	read -e -i "$force" -p "> Redirect non-www requests to 'www.' (Y/n) ? " input
	force="${input:-$force}"
	echo ""
else
	force="n"
fi


# FOR TESTING ONLY
#template="a"
#read -e -i "$template" -p "> Which template [a|b|c|d|e|f] ? " input
#template="${input:-$template}"
#sudo cp /home/steve/templates/new/$template.conf /etc/apache2/sites-available/$1.$TLD.conf
# END FOR TESTING ONLY

# Check for existence of SSL certificate and enable mod_ssl
if [[ $ssl =~ [A-Z] && $ssl == "Y" ]]; then
    #sudo openssl req -x509 -nodes -days 365 -subj "/C=GB/ST=Sussex/L=Horsham/O=Boilus Bum Boilus/OU=Certification/CN=$1" -newkey rsa:2048 -keyout /etc/ssl/private/"$1".key -out /etc/ssl/certs/"$1".crt

	#if sudo [ ! -d "/etc/letsencrypt/live/$1.$TLD" ]; then
	#	echo "ERROR: The certificate directory /etc/letsencrypt/live/$1.$TLD does not"
	#	echo "exist which will cause Apache to throw an error."
	#	echo "See the 'Configure SSL Certificates with Let’s Encrypt' section of the"
	#	echo "'Digital Ocean VPS Configuration.docx' document."
	#	exit -1
	#fi

    if [ ! -f "/etc/apache2/mods-enabled/ssl.load" ]; then
	    sudo a2enmod ssl
    fi
fi
sudo mkdir -p /var/www/"$1"/public_html
sudo chown -R $USER:$USER /var/www/"$1"/public_html
sudo chmod -R 755 /var/www

# Give user 'steve' full access to /var/www/$1.$TLD/ and all its files and sub-directories to allow correct use in ForkLift
sudo setfacl -R -m user:$USER:rwx /var/www/"$1"

#VER=$(date "+%Y-%m-%d %H:%M:%S")
day=$(date +%a)
tz=$(date +%Z)
VER=$(date "+FAC-`echo "$day" | perl -ne 'print lc'`%Y%m%d%H%M%S`echo "$tz" | perl -ne 'print lc'`")

cp /home/steve/templates/index.html /var/www/"$1"/public_html/index.html
sudo sed -i 's/REPLACE WITH TITLE/'"$1"' | Coming Soon/g' /var/www/"$1"/public_html/index.html
sudo sed -i 's/REPLACE WITH DOMAIN/'"$1"'/g' /var/www/"$1"/public_html/index.html
sudo sed -i 's/REPLACE WITH TAG LINE/The future home of something new/g' /var/www/"$1"/public_html/index.html
sudo sed -i 's/REPLACE WITH VERSION/'"$VER"'/g' /var/www/"$1"/public_html/index.html

cp /home/steve/templates/error.php /var/www/"$1"/public_html/error.php
cp /home/steve/templates/info.php /var/www/"$1"/public_html/info.php

if [ ! -f "/var/www/html/error.php" ]; then
	sudo cp /home/steve/templates/error.php /var/www/html/error.php
fi

#FILE="/var/www/html/info.php"
#if [ ! -f "/var/www/html/info.php" ]; then
#	sudo cp /home/steve/templates/info.php /var/www/html/info.php
#fi

#if [ ! -f "/var/www/html/index.php" ]; then
	#sudo cp /home/steve/templates/index.php /var/www/html/index.php
#fi


#cp /home/steve/templates/.htaccess /var/www/$1.$TLD/public_html/.htaccess
#sed -i 's/example.com/'"$1"'.'"$TLD"'/g' /var/www/$1.$TLD/public_html/.htaccess

#echo '# Directives for this site can be found in /etc/apache2/sites-available/'"$1"'.'"$TLD"'.conf' >> .htaccess
#sudo mv .htaccess /var/www/$1.$TLD/public_html/.htaccess

n=$(date "+%d/%m/%y at %H:%M:%S")

if [[ $ssl =~ [A-Z] && $ssl == "Y" ]]; then
	if [[ $www =~ [A-Z] && $www == "Y" ]]; then
		if [[ $force =~ [A-Z] && $force == "Y" ]]; then
			sudo cp /home/steve/templates/php-fpm/-a-vhost-config-template-ssl-www-force.conf /etc/apache2/sites-available/"$1".conf
		else
			sudo cp /home/steve/templates/php-fpm/-b-vhost-config-template-ssl-www.conf /etc/apache2/sites-available/"$1".conf
		fi
	else
		sudo cp /home/steve/templates/php-fpm/-c-vhost-config-template-ssl.conf /etc/apache2/sites-available/"$1".conf
	fi
else
	if [[ $www =~ [A-Z] && $www == "Y" ]]; then
		if [[ $force =~ [A-Z] && $force == "Y" ]]; then
			sudo cp /home/steve/templates/php-fpm/-d-vhost-config-template-www-force.conf /etc/apache2/sites-available/"$1".conf
		else
			sudo cp /home/steve/templates/php-fpm/-e-vhost-config-template-www.conf /etc/apache2/sites-available/"$1".conf
		fi
	else
		sudo cp /home/steve/templates/php-fpm/-f-vhost-config-template.conf /etc/apache2/sites-available/"$1".conf
	fi
fi

# TEMPORARILY COMMENTED-OUT FOR TESTING
#if [[ $ssl =~ [A-Z] && $ssl == "Y" ]]; then
#	if [[ $www =~ [A-Z] && $www == "Y" ]]; then
#		sudo cp /home/steve/templates/vhost-config-template-http-s.conf /etc/apache2/sites-available/$1.$TLD.conf
#	else
#		sudo cp /home/steve/templates/vhost-config-template-http-s-no-www.conf /etc/apache2/sites-available/$1.$TLD.conf
#	fi
#else
#	sudo cp /home/steve/templates/vhost-config-template-http.conf /etc/apache2/sites-available/$1.$TLD.conf
#fi
# END

sudo sed -i 's/EXAMPLE.COM/'"$1"'/g' /etc/apache2/sites-available/"$1".conf
sudo sed -i 's/POOL/'"$pool"'/g' /etc/apache2/sites-available/"$1".conf

# The / separator replaced with ! in sed to avoid conflict with / in $n date
sudo sed -i 's!# Created on!# Created on '"$n"' by '"$0"'!g' /etc/apache2/sites-available/"$1".conf

#sudo sed -i 's/\*:80/\*:'"$apacheport"'/g' /etc/apache2/sites-available/$1.$TLD.conf

# TEMPORARILY COMMENTED=OUT FOR TESTING
#if ! [[ $ssl =~ [A-Z] && $ssl == "Y" ]]; then
#	if [[ "$1" =~ "." ]]; then
#		sudo sed -i 's!ServerAlias!# ServerAlias commented-out as invalid by '"$0"'\n\t#ServerAlias!g' /etc/apache2/sites-available/$1.$TLD.conf
#	fi
#fi
# END

sudo a2ensite "$1".conf

echo "Restarting Apache"
sudo systemctl restart apache2

echo "Restarting PHP-FPM"
sudo systemctl restart php7.0-fpm

if [[ $ssl =~ [A-Z] && $ssl == "Y" ]]; then
	echo ""
	echo "WARNING: This virtual host has been configured to rewrite all requests to HTTPS."
	echo "To avoid a redirect loop ensure $1 is paused – not active – on Cloudflare."
	echo ""
fi

if [ ! -f /etc/php/7.0/fpm/pool.d/$pool.conf ]; then
	echo ""
	echo "WARNING: The pool '/etc/php/7.0/fpm/pool.d/$pool.conf' does not exist and needs"
	echo "to be created in order for this virtual host to function correctly."
	echo ""
fi

ip=$(ifconfig | grep '192\.' | awk  '{ print $2 }')
echo ""
echo "REMEMBER: Add '$ip $1' to '/etc/hosts' on your Mac"
echo ""
