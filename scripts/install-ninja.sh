#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian11 im LXC Container

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

apt-get install nginx mariadb-server php php-fpm php-cli php-common php-curl php-gd php-mysql php-xml php-bcmath php-json php-tokenizer php-mbstring php-gmp php-zip unzip vim -y

systemctl start nginx
systemctl start mariadb

mysql -u root <<EOF
        CREATE DATABASE  ninja;
        CREATE USER ninja@localhost IDENTIFIED BY 'ninja';
        GRANT ALL PRIVILEGES ON ninja.* TO ninja@localhost;
        FLUSH PRIVILEGES;
EOF

#echo "Invoice Ninja V4 installieren"
#echo "**************************************************"
#apt install -y unzip
#cd /var/www/html
#wget -O invoice-ninja.zip https://download.invoiceninja.com/
#unzip invoice-ninja.zip
#wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.5.16/invoiceninja.zip
#unzip invoiceninja.zip

#chown www-data:www-data /var/www/html/ninja/ -R


#echo "Invoice Ninja V5 installieren"
#echo "**************************************************"
apt install -y unzip
cd /var/www/html
mkdir ninja
cd ninja
wget -O invoice-ninja.zip https://github.com/invoiceninja/invoiceninja/releases/download/v5.5.16/invoiceninja.zip
unzip invoiceninja.zip

chown www-data:www-data /var/www/html/ninja/ -R

# conf erzeugen
###############################################################################
tee /etc/nginx/conf.d/ninja.conf >/dev/null <<EOF
server {
    listen 80;
    server_name ninja.invoice-ninja.spoor.local;

    root /var/www/html/ninja/public/;
    index index.php index.html index.htm;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log  /var/log/nginx/invoiceninja.access.log;
    error_log   /var/log/nginx/invoiceninja.error.log;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root$fastcgi_script_name;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

systemctl restart nginx

tee /etc/issue >/dev/null <<EOF
ninja.$(hostname -f);
\4

EOF



clear
echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://ninja.$(hostname -f)"
echo "IP: $IP"
