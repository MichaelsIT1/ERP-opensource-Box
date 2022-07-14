echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
################################ Update your Debian Installation  ###################################################
# Non-free aktivieren
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free
EOF

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y

apt install curl apt-transport-https gnupg -y

echo "installing Elasticsearch"
apt install apt-transport-https sudo wget curl gnupg -y
echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main"| \
tee -a /etc/apt/sources.list.d/elastic-7.x.list > /dev/null
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null
apt update -y
apt install elasticsearch -y
/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment

systemctl start elasticsearch
systemctl enable elasticsearch

echo "Add Repository and install Zammad"
echo "*************************************"
curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/pkgr-zammad.gpg> /dev/null
  
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 11 main"| \
  tee /etc/apt/sources.list.d/zammad.list > /dev/null
  
apt update -y
apt install zammad -y

echo "SELinux"
echo "**********"
# Allow nginx or apache to access public files of Zammad and communicate
chcon -Rv --type=httpd_sys_content_t /opt/zammad/public/
setsebool httpd_can_network_connect on -P
semanage fcontext -a -t httpd_sys_content_t /opt/zammad/public/
restorecon -Rv /opt/zammad/public/
chmod -R a+r /opt/zammad/public/

# Set the Elasticsearch server address
zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"

# Build the search index
zammad run rake zammad:searchindex:rebuild












# Zammad service to start all services at once
#systemctl (status|start|stop|restart) zammad

$ # Zammads internal puma server (relevant for displaying the web app)
#systemctl (status|start|stop|restart) zammad-web

$ # Zammads background worker - relevant for all delayed- and background jobs
#systemctl (status|start|stop|restart) zammad-worker

$ # Zammads websocket server for session related information
#systemctl (status|start|stop|restart) zammad-websocket

