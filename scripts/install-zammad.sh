#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf debian 12 im LXC Container

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

curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/pkgr-zammad.gpg> /dev/null

echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 12 main"| \
   tee /etc/apt/sources.list.d/zammad.list > /dev/null

apt update
apt install zammad -y

# Allow nginx or apache to access public files of Zammad and communicate
chcon -Rv --type=httpd_sys_content_t /opt/zammad/public/
setsebool httpd_can_network_connect on -P
semanage fcontext -a -t httpd_sys_content_t /opt/zammad/public/
restorecon -Rv /opt/zammad/public/
chmod -R a+r /opt/zammad/public/

 # Zammad service to start all services at once
 systemctl (status|start|stop|restart) zammad

 # Zammads internal puma server (relevant for displaying the web app)
 systemctl (status|start|stop|restart) zammad-web

 # Zammads background worker - relevant for all delayed- and background jobs
 systemctl (status|start|stop|restart) zammad-worker

 # Zammads websocket server for session related information
 systemctl (status|start|stop|restart) zammad-websocket

 

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
