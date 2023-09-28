#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf debian 12 im LXC Container

NOSSL=true

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

# generate and update the locales
apt install locales -y
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
#echo "LANG=en_US.UTF-8" > /etc/default/locale

# Install Elasticsearch
apt install sudo gnupg2 apt-transport-https curl vim -y

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch --no-check-certificate \
| gpg --dearmor > /etc/apt/trusted.gpg.d/elastic.gpg

echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" \
| tee -a /etc/apt/sources.list.d/elastic-8.x.list

apt update
apt install elasticsearch -y


# Install Zammad Ticketing System
wget -qO- https://dl.packager.io/srv/zammad/zammad/key \
| gpg --dearmor > /etc/apt/trusted.gpg.d/zammad.gpg

echo "deb https://dl.packager.io/srv/deb/zammad/zammad/stable/debian 12 main" > /etc/apt/sources.list.d/zammad.list

apt update
apt install zammad -y

systemctl status zammad
systemctl stop zammad
systemctl start zammad
systemctl restart zammad
systemctl enable zammad

systemctl status zammad-web
systemctl stop zammad-web
systemctl start zammad-web
systemctl restart zammad-web

systemctl status zammad-worker
systemctl stop zammad-worker
systemctl start zammad-worker
systemctl restart zammad-worker

systemctl status zammad-websocket
systemctl stop zammad-websocket
systemctl start zammad-websocket
systemctl restart zammad-websocket


# Running Elasticsearch
systemctl enable --now elasticsearch

curl -XGET "https://localhost:9200" \
--cacert /etc/elasticsearch/certs/http_ca.crt \
-u elastic

# Set the Elasticsearch server address
zammad run rails r "Setting.set('es_url', 'http://zammad:9200')"

# Define Elasticsearch Authentication Credentials
set +o history
zammad run rails r "Setting.set('es_user', 'elastic')"
zammad run rails r "Setting.set('es_password', 'ucoAPGk-io-hwnPalUle')"
set -o history

zammad run rake zammad:searchindex:rebuild

zammad run rails r "Setting.set('es_attachment_ignore', [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ] )"
zammad run rails r "Setting.set('es_attachment_max_size_in_mb', 50)"

# Tune Elasticsearch
echo vm.max_map_count=262144 >> /etc/sysctl.conf
sysctl -p

echo "http.max_content_length: 400mb" >> /etc/elasticsearch/elasticsearch.yml

# Update Elasticsearch JVM heap size settings
echo '-Xms1g
-Xmx1g' > /etc/elasticsearch/jvm.options.d/jvm-custom-heap.options

systemctl stop elasticsearch
systemctl start elasticsearch

# Configure Web Server for Zammad
apt install apache2 apache2-utils


# no SSL
if ($NOSSL)
cp /opt/zammad/contrib/apache2/zammad.conf /etc/apache2/sites-enabled/

tee /etc/apache2/sites-enabled/zammad.conf>/dev/null <<EOF
#
# this is the apache config for zammad
#

# security - prevent information disclosure about server version
ServerTokens Prod

<VirtualHost *:80>
    # replace 'localhost' with your fqdn if you want to use zammad from remote
    ServerName $(hostname -f)

    ## don't loose time with IP address lookups
    HostnameLookups Off

    ## needed for named virtual hosts
    UseCanonicalName Off

    ## configures the footer on server-generated documents
    ServerSignature Off

    ProxyRequests Off
    ProxyPreserveHost On

    <Proxy 127.0.0.1:3000>
	Require local
    </Proxy>

    ProxyPass /assets !
    ProxyPass /favicon.ico !
    ProxyPass /apple-touch-icon.png !
    ProxyPass /robots.txt !
    ProxyPass /ws ws://127.0.0.1:6042/
    ProxyPass / http://127.0.0.1:3000/

    # change this line in an SSO setup
    RequestHeader unset X-Forwarded-User

    DocumentRoot "/opt/zammad/public"

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>

    <Directory "/opt/zammad/public">
        Options FollowSymLinks
	Require all granted
    </Directory>

</VirtualHost>
EOF
fi

# disable defaultsite
a2dissite 000-default.conf

systemctl restart apache2

# Install Postfix for Zammad Email Notifications
apt install postfix -y
ufw allow "WWW Full"












# Allow nginx or apache to access public files of Zammad and communicate
#chcon -Rv --type=httpd_sys_content_t /opt/zammad/public/
#setsebool httpd_can_network_connect on -P
#semanage fcontext -a -t httpd_sys_content_t /opt/zammad/public/
#restorecon -Rv /opt/zammad/public/
#chmod -R a+r /opt/zammad/public/

 

 






#sleep 5

echo "connect zammad"


# Build the search index
#zammad run rake zammad:searchindex:rebuild

echo "*******************************************************************************************"
echo "zammad erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://zammad/"
echo "Hinweis. Linux: /etc/hosts eintragen: $IP zammad"
echo "**************************************************************************"
