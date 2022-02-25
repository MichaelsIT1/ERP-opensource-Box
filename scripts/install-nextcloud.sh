#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "nextcloud installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem debian wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl php-ldap php-intl php-bcmath php-gmp php-imagick unzip zip vim -y
echo


############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE nextcloud;
        CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';
        GRANT ALL PRIVILEGES ON nextcloud . * TO 'nextcloud'@'localhost';
        FLUSH PRIVILEGES;
EOF

 # automatische Installation
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        nextcloud     # new root password
        nextcloud     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF

echo "nextcloud herunterladen"
echo "********************************"

#mkdir /var/www/html/nextcloud/
cd /var/www/html/

# Webinstalller
# wget https://download.nextcloud.com/server/installer/setup-nextcloud.php

## Offline-installer
#wget https://download.nextcloud.com/server/releases/nextcloud-23.0.2.zip
#unzip nextcloud*

echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html
echo

systemctl restart apache2

clear

echo "*******************************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/setup-nextcloud.php"
echo "Zugangsdaten: Benutzer: nextcloud, Passwort: nextcloud"
echo "**************************************************************************"
