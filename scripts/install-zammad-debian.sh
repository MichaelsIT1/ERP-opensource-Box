#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf debian 12 im LXC Container funktionort nicht

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear 

echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y

apt install apt-transport-https sudo wget curl gnupg libimlib2 -y

# Install Required Packages for Redis Installation on Debian
apt install software-properties-common apt-transport-https curl ca-certificates lsb-release gpg -y

# elastic search
echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main"| \
  tee -a /etc/apt/sources.list.d/elastic-7.x.list > /dev/null
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null

apt update
apt install elasticsearch -y
/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment

apt install locales -y
locale-gen de_DE.utf8
echo "LANG=de_DE.UTF-8" > /etc/default/locale

# zammad
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 12 main"| \
   tee /etc/apt/sources.list.d/zammad.list > /dev/null

echo "install zammad"
apt update
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
