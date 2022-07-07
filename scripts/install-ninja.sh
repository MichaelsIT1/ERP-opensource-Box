#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

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
echo "PHP wird installiert"
echo "**************************************************"
apt install php php-fpm php-bcmath php-ctype php-fileinfo php-json php-mbstring php-pdo php-tokenizer php-xml php-curl php-zip php-gmp php-gd php-mysqli mariadb-server mariadb-client curl git vim composer -y
echo

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
        CREATE DATABASE ninjal;
        CREATE USER 'ninja'@'localhost' IDENTIFIED BY 'ninja';
        GRANT ALL PRIVILEGES ON ninja . * TO 'ninja'@'localhost';
        FLUSH PRIVILEGES;
EOF



#mkdir -p /etc/nginx/cert
#openssl req -new -x509 -days 365 -nodes -out /etc/nginx/cert/ninja.crt -keyout /etc/nginx/cert/ninja.key
#rm /etc/nginx/sites-enabled/default

tee /etc/apache2/sites-available/invoice-ninja.conf >/dev/null <<EOF
 <VirtualHost *:80>
    ServerName invoice.yourdomain.com
    DocumentRoot /var/www/invoiceninja/public

    <Directory /var/www/invoiceninja/public>
       DirectoryIndex index.php
       Options +FollowSymLinks
       AllowOverride All
       Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/invoiceninja.error.log
    CustomLog ${APACHE_LOG_DIR}/invoiceninja.access.log combined

    Include /etc/apache2/conf-available/php7.4-fpm.conf
</VirtualHost>
EOF

a2ensite invoice-ninja.conf
a2enmod rewrite
systemctl restart apache2


cd /var/www/html
mkdir invoiceninja && cd invoiceninja
wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.4.8/invoiceninja.zip
unzip invoiceninja.zip


cp .env.example .env

chown -R www-data:www-data /usr/www/html/invoiceninja
php7.4 artisan optimize

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
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/"
