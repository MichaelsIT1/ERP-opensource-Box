#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
# https://help.xentral.com/hc/de/articles/360017377620-Installation-von-xentral-ab-Version-19-1

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "xentral opensource installieren"
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
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl unzip zip patch -y
echo
echo "xentral opensource herunterladen"
echo "********************************"
wget https://github.com/xentral-erp-software-gmbh/downloads/raw/master/installer.zip
echo
echo "Installer.zip wird entpackt und nach var/www/html verschoben"
echo "***********************************************************"
unzip installer.zip
mv installer.php /var/www/html/
echo
echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/
echo

if ! mysql -u root -e 'use xentral';
then
        echo "Maria-DB wird konfiguiert und Datenbank angelegt"
        echo "*************************"       
       
       # automatische Installation
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        xentral     # new root password
        xentral     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF
       
        mysql -u root <<EOF
        CREATE DATABASE xentral;
        CREATE USER 'xentral'@'localhost' IDENTIFIED BY 'xentral';
        GRANT ALL PRIVILEGES ON xentral . * TO 'xentral'@'localhost';
        FLUSH PRIVILEGES;
EOF
else
        echo "Datenbank xentral vorhanden"
        echo "****************************"
fi

echo "Cronjob wird erzeugt"
echo "********************"
crontab -u www-data -l > cron_bkp
echo "* * * * * /usr/bin/php /var/www/html/cronjobs/starter2.php" >> cron_bkp
crontab -u www-data cron_bkp
rm cron_bkp
clear
echo "*******************************************************************************************"
echo "Server wurde für die Installation von xentral openSource vorbereitet."
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/installer.php"
echo "Datenbank-Name: xentral, Datenbankbenutzer: xentral, Datenbankpasswort: xentral"
echo "**************************************************************************"
