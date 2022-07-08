#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu 20.04 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "Invoice Ninja installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
echo

apt-get install software-properties-common apt-transport-https ca-certificates gnupg2 -y
apt-get install apache2 mariadb-server -y

 apt-get install unzip php7.2 libapache2-mod-php7.2 php-imagick php7.2-fpm php7.2-mysql php7.2-common php7.2-gd php7.2-json php7.2-curl php7.2-zip php7.2-xml php7.2-mbstring php7.2-bz2 php7.2-intl php7.2-gmp unzip -y

mysql -u root <<EOF
        CREATE DATABASE  invoiceninjadb;
        create user invoiceninja@localhost identified by 'password123!';
        grant all privileges on invoicedb.* to invoice@localhost;
        FLUSH PRIVILEGES;
EOF

echo "Invoice Ninja installieren"
echo "**************************************************"
cd /var/www/
mkdir invoice-ninja && cd invoice-ninja
wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.4.8/invoiceninja.zip
unzip invoiceninja.zip

chown www-data:www-data /var/www/invoice-ninja/ -R
chmod 755 /var/www/invoice-ninja/storage/ -R

tee /etc/apache2/sites-available/invoice-ninja.conf >/dev/null <<EOF
 <VirtualHost *:80>
    ServerName invoice.$(hostname -f)
    DocumentRoot /var/www/invoice-ninja/public

    <Directory /var/www/invoice-ninja/public>
       DirectoryIndex index.php
       Options +FollowSymLinks
       AllowOverride All
       Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/invoice-ninja.error.log
    CustomLog ${APACHE_LOG_DIR}/invoice-ninja.access.log combined

    Include /etc/apache2/conf-available/php7.4-fpm.conf
</VirtualHost>
EOF

a2ensite invoice-ninja.conf
a2enmod rewrite
systemctl restart apache2
a2dissite 000-default.conf
systemctl reload apache2

clear
echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/ oder http://invoice.$(hostname -f)"
