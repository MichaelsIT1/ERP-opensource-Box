#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "open3a installieren"
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
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl unzip zip -y
echo


############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE open3a;
        CREATE USER 'open3a'@'localhost' IDENTIFIED BY 'open3a';
        GRANT ALL PRIVILEGES ON open3a . * TO 'open3a'@'localhost';
        FLUSH PRIVILEGES;
EOF

cd /root/
echo "open3a herunterladen"
echo "********************************"
wget https://www.open3a.de/multiCMSDownload.php?filedl=133

mkdir /var/www/html/open3a/
mv multiCMSDownload.php\?filedl\=133 /var/www/html/open3a/
cd /var/www/html/open3a/
unzip multiCMSDownload.php?filedl=133


echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/open3a
echo
       
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
       
  chmod 777 specifics/
  chmod 777 system/Backup/


e
echo "*******************************************************************************************"
echo "open3A erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/open3a/"
echo "**************************************************************************"
