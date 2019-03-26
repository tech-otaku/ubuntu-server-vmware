#!/bin/bash

clear

export location=/etc/ssl
read -e -i "$location" -p "> Parent directory for '/ca' directory: " input
location="${input:-$location}"

export country=GB
read -e -i "$country" -p "> 2-digit country code for certificates: " input
country="${input:-$country}"

export config="${location}"/ca/config/openssl.cnf
read -e -i "$config" -p "> Configuration file: " input
config="${input:-$config}"

export uri=192.168.239.139
read -e -i "$uri" -p "> URI for crl.pem: " input
uri="${input:-$uri}"
echo ""

continue="Y"
echo -e "This will delete the current root CA and all its signed certificates."
read -e -i "$continue" -p "> Do you want to continue (Y/n) ? " input
continue="${input:-$continue}"

if [[ $continue != "Y" ]]; then
	echo Exiting...
	exit 1
fi

parent=ca
[ -d "${location}/${parent}" ] && sudo rm -rf "${location}/${parent}"
echo "Deleted directory ${location}/${parent} ..."

sudo mkdir "${location}/${parent}"
echo "Created directory ${location}/${parent} ..."

dir=certs
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

dir=config
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

dir=crl
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

dir=newcerts
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

dir=private
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

perms=600
sudo chmod 600 "${location}/${parent}/${dir}"
echo "Changed permissions on ${location}/${parent}/${dir} to $perms ..."

dir=requests
sudo mkdir "${location}/${parent}/${dir}"
echo "Created directory ${location}/${parent}/${dir} ..."

file=index.txt
sudo touch "${location}/${parent}/${file}"
echo "Created file ${location}/${parent}/${file} ..."

file=index.txt.attr
echo 'unique_subject = no' | sudo tee  "${location}/${parent}/${file}" 1> /dev/null
echo "Created file ${location}/${parent}/${file} ..."

file=serial
echo '0001' | sudo tee "${location}/${parent}/${file}" 1> /dev/null
echo "Created file ${location}/${parent}/${file} ..."

file=pswd
echo 'camden' | sudo tee "${location}/${parent}/${file}" 1> /dev/null
echo "Created file ${location}/${parent}/${file} ..."

file=crlnumber
echo '00' | sudo tee "${location}/${parent}/${file}" 1> /dev/null
echo "Created file ${location}/${parent}/${file} ..."

dir=config
file=openssl.cnf
sudo cp --preserve=all /usr/lib/ssl/openssl.cnf "${location}/${parent}/$dir/${file}"
echo "Copied file /usr/lib/ssl/openssl.cnf to ${location}/${parent}/$dir/${file} ..."

file=openssl.bak
sudo cp --preserve=all /usr/lib/ssl/openssl.cnf "${location}/${parent}/$dir/${file}"
echo "Copied file /usr/lib/ssl/openssl.cnf to ${location}/${parent}/$dir/${file} ..."

sudo sed -i 's!\./demoCA\(.*Where\)!'"$location"'\/ca\1!g' $config
sudo sed -i 's/\(stateOrProvinceName.*\)match/\1optional/g' $config
sudo sed -i 's/\(organizationName.*\)match/\1optional/g' $config
sudo sed -i 's/\(\[.*usr_cert.*\]\)/\1\ncrlDistributionPoints=URI:http:\/\/'"$uri"'\/crl\/crl.pem/g' $config
sudo sed -i 's/\(\[.*v3_ca.*\]\)/\1\ncrlDistributionPoints=URI:http:\/\/'"$uri"'\/crl\/crl.pem/g' $config
echo "Configured $config ..."

sudo openssl \
genrsa \
-aes256 \
-out "${location}"/ca/private/cakey.pem \
-passout file:"${location}"/ca/pswd \
4096
echo "Generated CA private key at ${location}/ca/private/cakey.pem  ..."

sudo openssl \
req \
-config "${location}"/ca/config/openssl.cnf \
-new \
-x509 \
-subj "/C="${country}"/O=Boilus Bum Boilus/CN=BBB Root CA/" \
-key "${location}"/ca/private/cakey.pem \
-passin file:"${location}"/ca/pswd \
-out "${location}"/ca/cacert.pem \
-days 3650 \
-set_serial 0x1
echo "Generated CA certificate at ${location}/ca/cacert.pem ..."

dir=crl
[ ! -d /var/www/html/"${dir}" ] && sudo mkdir /var/www/html/"${dir}"
echo "Created directory /var/www/html/${dir}"

sudo openssl \
ca \
-config "${location}"/ca/config/openssl.cnf \
-gencrl \
-crldays 120 \
-passin file:"${location}"/ca/pswd \
-out /var/www/html/crl/crl.pem
echo "Generated CRL at /var/www/html/crl/crl.pem"

