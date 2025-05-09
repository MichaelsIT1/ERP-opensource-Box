#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian12 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

VERSION=https://github.com/invoiceninja/invoiceninja/releases/download/v5.11.73/invoiceninja.tar




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

apt install apache2  php-fpm php-soap php-bcmath php-common php-imagick php-mysql php-gmp php-curl php-intl php-mbstring php-xmlrpc php-gd php-xml php-cli php-zip php-bz2 -y
apt install mariadb-server mariadb-client libapache2-mod-php unzip vim -y

systemctl start mariadb
systemctl enable mariadb && systemctl start mariadb

mysql -u root <<EOF
        CREATE DATABASE  ninja;
        CREATE USER ninja@localhost IDENTIFIED BY 'ninja';
        GRANT ALL PRIVILEGES ON ninja.* TO ninja@localhost;
        FLUSH PRIVILEGES;
EOF

apt update
apt install wget curl unzip vim -y

#echo "Invoice Ninja V5 installieren"
#echo "**************************************************"
mkdir  /var/www/invoice_ninja
cd /var/www/invoice_ninja

# Software herunterladen und entpacken
#wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.10.57/invoiceninja.tar
#wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.11.71/invoiceninja.tar
wget $VERSION
tar -xf invoiceninja.tar

chown -R www-data:www-data /var/www/invoice_ninja
chmod -R 755 /var/www/invoice_ninja

cd /var/www/invoice_ninja
cp .env.example .env

chown www-data:www-data /var/www/invoice_ninja/.env

# conf erzeugen
###############################################################################
tee /etc/apache2/sites-available/invoice_ninja.conf >/dev/null <<EOF
<VirtualHost *:80>
    ServerName invoiceninja.$(hostname -f);
    DocumentRoot /var/www/invoice_ninja/public
    <Directory /var/www/invoice_ninja/public>
       DirectoryIndex index.php
       Options +FollowSymLinks
       AllowOverride All
       Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/invoice_ninja_error.log
    CustomLog ${APACHE_LOG_DIR}/invoice_ninja_access.log combined
</VirtualHost>
EOF

a2ensite invoice_ninja.conf

a2enmod mpm_event proxy_fcgi setenvif
a2enconf php8.2-fpm
a2enmod rewrite 
a2dissite 000-default.conf

systemctl restart apache2
systemctl reload apache2

clear

chown -R www-data:www-data /var/www/invoice_ninja
chmod -R 755 /var/www/invoice_ninja

tee /etc/issue >/dev/null <<EOF
ninja.$(hostname -f);
\4

EOF

clear

echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://invoiceninja.$(hostname -f)"
echo "Datanbanksettings: DB, DB-Passwort ninja"
echo "IP: $IP"
