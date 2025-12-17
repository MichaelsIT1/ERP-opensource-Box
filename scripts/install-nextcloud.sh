#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 13 im LXC Container

# System-Varibale
ONLINEINSTALL=true
OFFLINEINSTALL=false



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
apt update
apt update && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install curl sudo apache2 mariadb-server php php-mbstring php-soap php-xml php-zip php-gd php-cli php-mysql php-curl php-ldap php-intl php-bcmath php-gmp php-imagick unzip zip vim -y
echo
apt install php-intl php-imagick php-apcu -y
apt install libmagickcore-7.q16-10-extra -y

############# Datenbank erzeugen #########################
mysql -u root <<EOF
        CREATE DATABASE nextcloud;
        CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';
        GRANT ALL PRIVILEGES ON nextcloud . * TO 'nextcloud'@'localhost';
        FLUSH PRIVILEGES;
EOF

 # automatische Installation
#        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
#                    # current root password (emtpy after installation)
#        y           # Set root password?
#        nextcloud     # new root password
#        nextcloud     # new root password         
#        y           # Remove anonymous users?
#        y           # Disallow root login remotely?
#        y           # Remove test database and access to it?
#        y           # Reload privilege tables now?
#EOF

echo "nextcloud herunterladen"
echo "********************************"

#mkdir /var/www/html/nextcloud/
cd /var/www/html/

if ($ONLINEINSTALL)
then
# Webinstalller
 wget https://download.nextcloud.com/server/installer/setup-nextcloud.php
fi



# Offline-installer FEHLERHAFT
if ($OFFLINEINSTALL)
then
wget https://download.nextcloud.com/server/releases/nextcloud-23.0.2.zip
unzip nextcloud*
fi


echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html
echo



# PHP Memeory limit anpassen
sed -i "s|memory_limit = 128M|memory_limit = 1048M|g" /etc/php/*/apache2/php.ini

# Die Zeile einfügen und output_buffering ausschalten
echo "output_buffering = off" >> /etc/php/*/apache2/php.ini

echo "Redirect 301 /.well-known/carddav /nextcloud/remote.php/dav" >> /etc/apache2/sites-enabled/000-default.conf
echo "Redirect 301 /.well-known/caldav /nextcloud/remote.php/dav" >> /etc/apache2/sites-enabled/000-default.conf
echo "Redirect 301 /.well-known/webfinger /nextcloud/index.php/.well-known/webfinger" >> /etc/apache2/sites-enabled/000-default.conf
echo "Redirect 301 /.well-known/nodeinfo /nextcloud/index.php/.well-known/nodeinfo" >> /etc/apache2/sites-enabled/000-default.conf


systemctl restart apache2

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
\4/nextcloud
EOF

clear

echo "*******************************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/setup-nextcloud.php"
echo "für die Einrichtung Zugangsdaten:" 
echo "Benutzer: nextcloud"
echo "Passwort: nextcloud" 
echo "Datenbank: nextcloud" 
echo "DB-PW: nextcloud" 
echo "DB-Server: localhost"
echo "**************************************************************************"
