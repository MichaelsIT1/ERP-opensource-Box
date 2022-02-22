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
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl php-ldap unzip zip -y
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
        open3a     # new root password
        open3a     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF

echo "nextcloud herunterladen"
echo "********************************"

#mkdir /var/www/html/nextcloud/
cd /var/www/html/

wget https://download.nextcloud.com/server/installer/setup-nextcloud.php


echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html
echo

systemctl restart apache2

clear

echo "*******************************************************************************************"
echo "nextcloud: Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/setup-nextcloud.php"
echo "Zugangsdaten: Host: localhost, Benutzer: nextcloud, Passwort: nextcloud, Datenbank: nextcloud, Passwort: nextcloud"
echo "**************************************************************************"
