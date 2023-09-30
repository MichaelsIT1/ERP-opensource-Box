#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu 20.04 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear

echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
apt-get install wget apt-transport-https gnupg curl -y

# debian 11 gpg key
wget -qO- https://dl.packager.io/srv/zammad/zammad/key | sudo apt-key add -
wget -O /etc/apt/sources.list.d/zammad.list \
  https://dl.packager.io/srv/zammad/zammad/stable/installer/debian/11.repo
apt-get update

echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 11 main"| \
   tee /etc/apt/sources.list.d/zammad.list > /dev/null

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null

apt update
apt install elasticsearch -y
/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment


apt install locales -y
locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/default/locale

wget -qO- https://dl.packager.io/srv/zammad/zammad/key | sudo apt-key add -
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 11 main"| \
   tee /etc/apt/sources.list.d/zammad.list > /dev/null  

echo "install zammad"
apt update -y
apt install zammad -y

sleep 5

sed -i "s|    server_name localhost;|    server_name zammad;|g" /etc/nginx/sites-available/zammad.conf  
systemctl restart nginx

sleep 5

echo "connect zammad"
# Set the Elasticsearch server address
zammad run rails r "Setting.set('es_url', 'http://zammad:9200')"

# Build the search index
zammad run rake zammad:searchindex:rebuild

echo "*******************************************************************************************"
echo "zammad erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://zammad/"
echo "Hinweis. Linux: /etc/hosts eintragen: $IP zammad"
echo "**************************************************************************"
