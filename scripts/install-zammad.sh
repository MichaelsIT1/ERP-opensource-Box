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



apt install apt-transport-https sudo wget curl gnupg -y
echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main"| \
  tee -a /etc/apt/sources.list.d/elastic-7.x.list > /dev/null
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null
apt update -y
apt install elasticsearch -y
/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment

apt install locales -y
locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/default/locale

wget -qO- https://dl.packager.io/srv/zammad/zammad/key | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/zammad.list \
  https://dl.packager.io/srv/zammad/zammad/stable/installer/ubuntu/20.04.repo

echo "install zammad"
apt update -y
apt install zammad -y

sleep 10

echo "connect zammad"
# Set the Elasticsearch server address
zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"

# Build the search index
zammad run rake zammad:searchindex:rebuild

echo "*******************************************************************************************"
echo "zammad erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP//"
echo "**************************************************************************"
