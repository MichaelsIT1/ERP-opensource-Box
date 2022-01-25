#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
# https://www.howtoforge.com/ispconfig-autoinstall-debian-ubuntu/

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "ISP-Config installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
echo
echo "ISP-Config wird installiert"
echo "**************************************************"
wget -O - https://get.ispconfig.org | sh -s -- --use-ftp-ports=40110-40210 --unattended-upgrades --i-know-what-i-am-doing --no-quota --use-php=8.0,8,1
echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "**************************************************************************"
