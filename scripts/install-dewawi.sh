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
apt install apache2 mariadb-server php php-mbstring php-soap php-xml php-zip php-gd php-cli php-mysql php-curl php-intl php-ssh2 unzip zip -y
echo


############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE dewawi;
        CREATE USER 'dewawi'@'localhost' IDENTIFIED BY 'dewawi';
        GRANT ALL PRIVILEGES ON dewawi . * TO 'dewawi'@'localhost';
        FLUSH PRIVILEGES;
EOF

echo "dewawi herunterladen"
echo "********************************"
cd /var/www/html
wget https://github.com/dewawi/dewawi/archive/1.1.2.zip
unzip 1.1.2.zip
mv dewawi-1.1.2/ dewawi 

echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/dewawi
echo
systemctl restart apache2
clear
echo "*******************************************************************************************"
echo "dewawi installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/"
echo "Database name: dewawi, Username: dewawi, Password: dewawi"
echo "Loginseite: http://$IP/dewawi/index.php/"
echo "**************************************************************************"
