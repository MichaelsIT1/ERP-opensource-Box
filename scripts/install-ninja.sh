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


echo "Apache Webserver wird installiert"
echo "**************************************************"
apt install -y apache2 apache2-utils

systemctl start apache2
systemctl enable apache2

chown www-data:www-data /var/www/html/ -R


echo "MariaDB Datenbankserver wird installiert"
echo "**************************************************"
apt install -y mariadb-server mariadb-client

systemctl start mariadb
systemctl enable mariadb

#automatische Installation
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        ninja     # new root password
        ninja     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF

 mysql -u root <<EOF
        CREATE DATABASE ninja;
        CREATE USER 'ninja'@'localhost' IDENTIFIED BY 'ninja';
        GRANT ALL PRIVILEGES ON ninja . * TO 'ninja'@'localhost';
        FLUSH PRIVILEGES;
EOF


echo "PHP wird installiert"
echo "**************************************************"
apt install php php-fpm php-bcmath php-ctype php-fileinfo php-json php-mbstring php-pdo php-tokenizer php-xml php-curl php-zip php-gmp php-gd php-mysqli curl git vim composer -y
echo

apt install -y php7.4 libapache2-mod-php7.4 php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline

a2enmod php7.4
systemctl restart apache2


echo "Run PHP-FPM with Apache"
echo "**************************************************"

a2dismod php7.4
apt install -y php7.4-fpm
a2enmod proxy_fcgi setenvif

a2enconf php7.4-fpm
systemctl restart apache2

echo "Invoice Ninja installieren"
echo "**************************************************"
cd /var/www/
mkdir invoice-ninja && cd invoice-ninja
wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.4.8/invoiceninja.zip
unzip invoiceninja.zip

chown www-data:www-data /var/www/invoice-ninja/ -R
chmod 755 /var/www/invoice-ninja/storage/ -R

a2dismod mpm_prefork

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








#cp .env.example .env


#php7.4 artisan optimize

#echo "Cronjob wird erzeugt"
#echo "********************"
#crontab -u www-data -l > cron_bkp
#echo "* * * * * php7.4 /usr/share/nginx/invoiceninja/artisan schedule:run >> /dev/null 2>&1" >> cron_bkp
#crontab -u www-data cron_bkp
#rm cron_bkp
#clear

clear
echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/ oder http://invoice.$(hostname -f)"
