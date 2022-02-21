#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "i-doit installieren"
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
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl php-ldap unzip zip graphviz -y
echo


############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE idoit;
        CREATE USER 'idoit'@'localhost' IDENTIFIED BY 'idoit';
        GRANT ALL PRIVILEGES ON idoit . * TO 'idoit'@'localhost';
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


echo "i-doit herunterladen"
echo "********************************"
cd /root/
wget https://sourceforge.net/projects/i-doit/files/latest/download

mkdir /var/www/html/idoit/
mv download /var/www/html/idoit/
cd /var/www/html/idoit/
unzip download


echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/itop
echo
       
# Rechte setzen
 # chmod 777 specifics/
 # chmod 777 system/Backup/

systemctl restart apache2

echo "*******************************************************************************************"
echo "iTop erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/idoit"
echo "Zugangsdaten: Host: localhost, Benutzer: idoit, Passwort: idoit, Datenbank: idoit, Passwort: idoit"
echo "**************************************************************************"
