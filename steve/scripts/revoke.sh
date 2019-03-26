IFS=$'\n'       # make newlines the only separator
set -f          # disable globbing
revoked=255		# false

sudo openssl ca -config "${location}"/ca/config/openssl.cnf -passin file:"${location}"/ca/pswd updatedb

for i in $(cat < /etc/ssl/ca/index.txt); do 
	if [ $(echo $i | grep $1) ]; then
		state=$(echo $i | awk '{print $1}') 
		if [ $state == V ]; then
			serial=$(echo $i | awk '{print $3}')
			#echo $state:$serial
			sudo openssl ca -config "${location}"/ca/config/openssl.cnf -passin file:"${location}"/ca/pswd -revoke "${location}"/ca/newcerts/$serial.pem
			revoked=0	# true
		fi
	fi
done

#if [[ revoked -eq 0 ]]; then

	[ ! -d /var/www/html/crl ] && sudo mkdir /var/www/html/crl

	sudo openssl ca -config "${location}"/ca/config/openssl.cnf -gencrl -crldays 120 -passin file:"${location}"/ca/pswd -out /var/www/html/crl/crl.pem
	
	echo "New CRL generated"
	
#fi