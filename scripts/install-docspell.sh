#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# Doku
# https://github.com/andreklug/docspell-debian

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "docspell installieren"
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

apt install curl htop zip gnupg2 ca-certificates sudo -y
apt install default-jdk apt-transport-https wget -y
apt install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf -y

echo "SOLR Installation"
echo "**********************************"
cd /root/
wget https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz
sleep 5
tar xzf solr-8.11.2.tgz
sleep 5
bash solr-8.11.2/bin/install_solr_service.sh solr-8.11.2.tgz
sleep 5
systemctl start solr
sleep 5
su solr -c '/opt/solr-8.11.2/bin/solr create -c docspell'




echo "PostgreSQL Installation"
echo "**********************************"
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/postgresql.list'
sleep 5
apt update && apt full-upgrade -y
apt install postgresql-14 -y

sleep 5

echo "scheduled database backup"
echo "**********************************"
echo "fehlt weil ZFS ingesetzt wird"
# crontab -u postgres -e
# 11 1 * * * sh /opt/postgres-backup.sh


echo "Docspell installation"
echo "**********************************"
cd /tmp
wget https://github.com/eikek/docspell/releases/download/v0.38.0/docspell-joex_0.38.0_all.deb
sleep 5
wget https://github.com/eikek/docspell/releases/download/v0.38.0/docspell-restserver_0.38.0_all.deb
sleep 5
dpkg -i docspell*

sleep 10

echo "commandline tool dsc"
echo "**********************************"
wget https://github.com/docspell/dsc/releases/download/v0.9.0/dsc_amd64-musl-0.9.0
mv dsc_amd* dsc
chmod +x dsc
mv dsc /usr/bin

echo "Dienste neu starten"
echo "*************************"
systemctl start docspell-restserver
systemctl enable docspell-restserver
systemctl start docspell-joex
systemctl enable docspell-joex


apt install nginx -y
sleep 5
openssl dhparam -out /etc/nginx/dhparam.pem 2048
sleep 5
rm /etc/nginx/sites-available/default
sleep 5

echo "new default config"
echo "**********************"
tee /etc/nginx/sites-available/default >/dev/null <<EOF
client_max_body_size 200M;
    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }

server {
    listen 0.0.0.0:80 ;
    listen [::]:80 ;
    server_name docs.home ;
    location /.well-known/acme-challenge {
        root /var/data/nginx/ACME-PUBLIC;
        auth_basic off;
    }
    location / {
        return 301 https://\$host$request_uri;
    }
}
server {
    listen 0.0.0.0:443 ssl http2 ;
    listen [::]:443 ssl http2 ;
    server_name docs.home ;
    location /.well-known/acme-challenge {
        root /var/data/nginx/ACME-PUBLIC;
        auth_basic off;
    }
    ssl_certificate /etc/nginx/ssl/docs.home.crt;
    ssl_certificate_key /etc/nginx/ssl/docs.home.key;
    #ssl_trusted_certificate /etc/nginx/ssl/homelab.local_CA.crt;
    access_log /var/log/nginx/docs.home.access.log;
    error_log /var/log/nginx/docs.home.error.log;
    ssl_protocols TLSv1.2;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_ecdh_curve secp384r1;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_session_timeout  10m;
    ssl_session_tickets off;
    #ssl_stapling on;
    #ssl_stapling_verify on;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    resolver 192.168.11.1 valid=300s;
    resolver_timeout 5s;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

 location / {
     proxy_pass http://127.0.0.1:7880;
     proxy_http_version 1.1;
     proxy_set_header Upgrade \$http_upgrade;
     proxy_set_header Connection \$connection_upgrade;
     proxy_set_header X-Real-IP \$remote_addr;
     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto \$scheme;
     proxy_set_header X-Forwarded-Host \$host;
  }


location /solr {
     proxy_pass http://127.0.0.1:8983;
     proxy_http_version 1.1;
#     proxy_set_header Upgrade \$http_upgrade;
#     proxy_set_header Connection \$connection_upgrade;
     proxy_set_header X-Real-IP \$remote_addr;
     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto \$scheme;
     proxy_set_header X-Forwarded-Host \$host;
  }


}
EOF

mkdir /etc/nginx/ssl 
sleep 5
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/docs.home.key -out /etc/nginx/ssl/docs.home.crt
sleep 5
sed -i "s|ssl_trusted_certificate /etc/nginx/ssl/homelab.local_CA.crt;|#ssl_trusted_certificate /etc/nginx/ssl/homelab.local_CA.crt;|g" /etc/nginx/sites-enabled/default

























#nächste manuelle Schritte



#echo "PostgreSQL User anlegen"
#echo "**********************************"


# OFFEN
# Bitte folgende Schritte ausfuehren

#sudo su -
#root@debian-11:~# su - postgres
#postgres@debian-11:~$ psql

#postgres=# CREATE USER docspell
#postgres-# WITH SUPERUSER CREATEDB CREATEROLE
#postgres-# PASSWORD 'docspell';

#postgres=# CREATE DATABASE docspelldb WITH OWNER docspell;
#postgres=# \connect docspelldb;
#You are now connected to database "docspelldb" as user "docspell".
#docspelldb=# \q
#exit
#systemctl enable postgresql




#in den Dateien
# /etc/docspell-joex/docspell-joex.conf
# /etc/docspell-restserver/docspell-server.conf
#eintragen bzw ändern

#   url = "jdbc:postgresql://localhost:5432/docspelldb"
#  user = "docspell"
#  password = "docspell"
  
#echo "SOLR full-text-suche enablen"
#full-text-search 
#enable = true



echo "*******************************************************************************************"
echo "docspell installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP/"
