#!/bin/bash

clear

echo '--> CONFIGURING.....'

tz="Europe/London"

echo '--> Suppressing the message "perl: warning: Setting locale failed.".....'
locale-gen en_GB.UTF-8

#echo '--> Installing systemd-services.....'
#apt-get install systemd-services	# allows for use of timedatectl

#echo '--> Installing zip/unzip.....'
#apt-get install zip unzip

n=$(date "+%d/%m/%y %H:%M:%S")
echo '--> Current date and time is '$n

echo '--> Setting time zone to '$tz '.....' 
timedatectl set-timezone $tz

n=$(date "+%d/%m/%y %H:%M:%S")
echo '--> Current date and time is '$n

echo '--> Configuring nano.....'
sed -i 's/# set tabsize 8/set tabsize 4/g' /etc/nanorc

#echo '--> Copying 000-default.conf to /etc/apache2/sites-available/.....'
#cp /root/config/000-default.conf /etc/apache2/sites-available/000-default.conf

#export PS1="\[\033[38;5;11m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\h:\[$(tput sgr0)\]\[\033[38;5;6m\][\w]:\[$(tput sgr0)\]\[\033[38;5;15m\] \\$\[$(tput sgr0)\]"

echo '--> CONFIGURATION COMPLETE.'