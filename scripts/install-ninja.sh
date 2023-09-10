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


echo "Invoice Ninja V5 installieren"
echo "**************************************************"
apt install -y unzip
cd /var/www/
mkdir invoiceninja
cd invoiceninja
wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.7.10/invoiceninja.zip
unzip invoiceninja.zip

chown www-data:www-data /var/www/invoiceninja/ -R

# conf erzeugen
###############################################################################
tee /etc/nginx/conf.d/invoiceninja.conf <<EOF
server {

listen 80;
server_name invoiceninja.$(hostname -f);
root /var/www/invoiceninja/public;
index index.php index.html index.htm;
client_max_body_size 20M;

gzip on;
gzip_types      application/javascript application/x-javascript text/javascript text/plain application/xml application/json;
gzip_proxied    no-cache no-store private expired auth;
gzip_min_length 1000;

location / {
    try_files $uri $uri/ =404;
}

location ~* \.pdf$ {
    add_header Cache-Control no-store;
}

if (!-e $request_filename) {
    rewrite ^(.+)$ /index.php?q= last;
}

location ~* /storage/.*\.php$ {
    return 503;
}

location ~ \.php$ {
include snippets/fastcgi-php.conf;
fastcgi_pass unix:/run/php/php8.1-fpm.sock;
}

location ~ /\.ht {
    deny all;
}

}
EOF

systemctl stop apache2
systemctl disable apache2
systemctl restart nginx

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
ninja.$(hostname -f);
\4

EOF



clear
echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://ninja.$(hostname -f)"
echo "IP: $IP"
