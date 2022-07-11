#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "DEWAWI installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl php-intl php-ssh2 unzip zip -y
echo


############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE open3a;
        CREATE USER 'dewawi'@'localhost' IDENTIFIED BY 'dewawi';
        GRANT ALL PRIVILEGES ON dewawi . * TO 'dewawi'@'localhost';
        FLUSH PRIVILEGES;
EOF

echo "dewawi herunterladen"
echo "********************************"
cd /var/www/html
wget https://github.com/dewawi/dewawi/archive/1.0.1.zip
unzip 1.0.1.zip
mv dewawi-1.0.1 dewawi

echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/dewawi
echo
clear
echo "*******************************************************************************************"
echo "dewawi installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/dewawi/"
echo "Database name: dewawi, Username: dewawi, Password: dewawi"
echo "**************************************************************************"
