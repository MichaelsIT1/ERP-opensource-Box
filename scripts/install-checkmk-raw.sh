#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "checkMK installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem debian wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl php-ldap unzip zip graphviz -y
echo


cd /root/
wget https://download.checkmk.com/checkmk/2.1.0p6/check-mk-raw-2.1.0p6_0.bullseye_amd64.deb

apt install ./check* -y

omd create TEST
omd start TEST

systemctl restart apache2

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
\4/TEST

EOF

echo "*******************************************************************************************"
echo "checkmk raw erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/TEST/"
echo "Bitte notieren Sie sich das Passwort für den Benutzer cmkadmin"
echo "**************************************************************************"
