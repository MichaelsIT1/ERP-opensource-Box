#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "itop installieren"
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
        CREATE DATABASE itop;
        CREATE USER 'itop'@'localhost' IDENTIFIED BY 'itop';
        GRANT ALL PRIVILEGES ON itop . * TO 'itop'@'localhost';
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


echo "itop herunterladen"
echo "********************************"
cd /root/
wget https://sourceforge.net/projects/itop/files/latest/download

mkdir /var/www/html/itop/
mv download /var/www/html/itop/
cd /var/www/html/itop/
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
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/itop/web/setup/wizard.php"
echo "Zugangsdaten: Host: localhost, Bentzer: itop, Passwort: itop, Datenbank: itop, Passwort: itop"
echo "**************************************************************************"
