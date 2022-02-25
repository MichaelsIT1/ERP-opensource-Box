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

# Offline-installer
wget https://download.nextcloud.com/server/releases/nextcloud-23.0.2.zip
unzip nextcloud*


curl /var/www/html/nextcloud/index.php


mv nextcloud/config/config.php nextcloud/config/config.php.org


#config/config.php erzeugen
tee /var/www/html/nextcloud/config/config.php >/dev/null <<EOF
  'passwordsalt' => 'n6hcplI/UzRHP9kRLM1gL4ISHQcEY0',
  'secret' => 'f1q9NmHPPDxriS8D0zBE1mdi1NkvsEZT5xUHrjnblaImuoDi',
  'trusted_domains' =>
  array (
    0 => '$IP',
  ),
  'datadirectory' => '/var/www/html/nextcloud/nextcloud/data',
  'dbtype' => 'mysql',
  'version' => '23.0.2.1',
  'overwrite.cli.url' => 'http://192.168.188.89/nextcloud/nextcloud',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'nextcloud',
  'default_language' => 'de',
  'default_locale' => 'de_DE',
  'default_phone_region' => 'DE',
  'installed' => true,
);
EOF











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
