echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y

apt install curl apt-transport-https gnupg -y

echo "installing Elasticsearch"
echo "***************************"
apt install apt-transport-https sudo wget curl gnupg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main"| \
  tee -a /etc/apt/sources.list.d/elastic-7.x.list > /dev/null
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null
apt update -y
apt install elasticsearch -y
sleep 5
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

# Set the Elasticsearch server address
zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"

# Build the search index
zammad run rake zammad:searchindex:rebuild

# Zammad service to start all services at once
systemctl restart zammad

$ # Zammads internal puma server (relevant for displaying the web app)
systemctl restart) zammad-web

$ # Zammads background worker - relevant for all delayed- and background jobs
systemctl restart zammad-worker

$ # Zammads websocket server for session related information
systemctl restart zammad-websocket

Set the Elasticsearch server address
$ zammad run rails r "Setting.set('es_url', 'http://localhost:9200')"

# Build the search index
$ zammad run rake zammad:searchindex:rebuild

echo "*******************************************************************************************"
echo "checkmk raw erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP//"
echo "**************************************************************************"
