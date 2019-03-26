#!/bin/bash

clear

file=/etc/ssl/ca/cacert.pem
if [ ! -f "$file" ]; then
  	echo -e "ERROR: The CA certificate ${file} doesn't exist.\nRun 'bash /home/steve/scripts/create-ca.sh' first."
    exit 1
fi

export location=/etc/ssl
read -e -i "$location" -p "> Parent directory for '/ca' directory: " input
location="${input:-$location}"

export country=GB
read -e -i "$country" -p "> 2-digit country code for certificates: " input
country="${input:-$country}"

export config="${location}"/ca/config/openssl.cnf
read -e -i "$config" -p "> Configuration file: " input
config="${input:-$config}"

export domain=ubuntu.
read -e -i "$domain" -p "> Domain name: " input
domain="${input:-$domain}"

export unit=minutes
read -e -i "$unit" -p "> Units for certificate length [minutes|hours|days|weeks|months|years]: " input
unit="${input:-$unit}"

export length=15
read -e -i "$length" -p "> Length of certificate validity in ${units}: " input
length="${input:-$length}"

source /home/steve/scripts/revoke.sh ${domain}
echo "Revoked all valid certificates for ${domain}"

sudo openssl \
genrsa \
-out "${location}"/ca/private/"${domain}".key.pem \
2048
echo "Generated private key for ${domain} at ${location}/ca/private/${domain}.key.pem ..."

sudo openssl \
req \
-config "${location}"/ca/config/openssl.cnf \
-new \
-subj "/C=${country}/CN=${domain}/" \
-key "${location}"/ca/private/"${domain}".key.pem \
-out "${location}"/ca/requests/"${domain}".csr
echo "Generated CSR for ${domain} at ${location}/ca/requests/${domain}.csr ..."

start=$(date +"%y%m%d%H%M%SZ")
end=$(date -d "$length $unit" +"%y%m%d%H%M%SZ")

sudo openssl \
ca \
-config "${location}"/ca/config/openssl.cnf \
-verbose \
-batch \
-passin file:"${location}"/ca/pswd \
-startdate $start \
-enddate $end \
-in "${location}"/ca/requests/"${domain}".csr \
-out "${location}"/ca/newcerts/"${domain}".pem
echo "Generated certificate for ${domain} at ${location}/ca/newcerts/${domain}.pem ..."

sudo service apache2 restart
echo "Restarted Apache ..."