#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu 20.04 im LXC Container

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
sleep 10
apt install php7.4 php7.4-fpm php7.4-bcmath php7.4-ctype php7.4-fileinfo php7.4-json php7.4-mbstring php7.4-pdo php7.4-tokenizer php7.4-xml php7.4-curl php7.4-zip php7.4-gmp php7.4-gd php7.4-mysqli mariadb-server mariadb-client curl git nginx vim composer -y

systemctl enable --now mariadb

mysql -u root <<EOF
        CREATE DATABASE  ninja;
        create user ninja@localhost identified by 'ninja';
        grant all privileges on ninja.* to ninja@localhost;
        FLUSH PRIVILEGES;
EOF

rm /etc/nginx/sites-enabled/default

# conf erzeugen
###############################################################################
tee /etc/nginx/conf.d/invoiceninja.conf >/dev/null <<EOF
server {
# NOTE That the 'default_server' option is only necessary if this is your primary domain application.
# If you run multiple subdomains from the same host already, remove the 'default_server' option.
   listen       443 ssl http2 default_server;
   listen       [::]:443 ssl http2 default_server;
   server_name  invoices.$(hostname -f);
   client_max_body_size 20M;

 # This if statement will forcefully redirect any connection attempts to explicitly use the domain name.  
 # If not, and your DNS doesn't provide IP address protection, accessing the server with direct IP can
 # cause glitches with the services provided by the app, that could be security, or usability issues.

   if ($host != $server_name) {
     return 301 https://$server_name$request_uri;
   }

 # Here, enter the path to your invoiceninja directory, in the public dir.  VERY IMPORTANT
 # DO NOT point the root directly at your invoiceninja directory, it MUST point at the public folder
 # This is for security reasons.
   root         /usr/share/nginx/invoiceninja/public;

   gzip on;
   gzip_types application/javascript application/x-javascript text/javascript text/plain application/xml application/json;
   gzip_proxied    no-cache no-store private expired auth;
   gzip_min_length 1000;

   index index.php index.html index.htm;

 # Enter the path to your existing ssl certificate file, and certificate private key file
 # If you don’t have one yet, you can configure one with openssl in the next step.
   ssl_certificate "/etc/nginx/cert/ninja.crt";
   ssl_certificate_key "/etc/nginx/cert/ninja.key";

   ssl_session_cache shared:SSL:1m;
   ssl_session_timeout  10m;
   ssl_ciphers 'AES128+EECDH:AES128+EDH:!aNULL';
   ssl_prefer_server_ciphers on;
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

   charset utf-8;

 # Load configuration files for the default server block.
   include /etc/nginx/default.d/*.conf;

   location / {
       try_files $uri $uri/ /index.php?$query_string;
   }

   if (!-e $request_filename) {
           rewrite ^(.+)$ /index.php?q= last;
   }

   location ~ \.php$ {
           fastcgi_split_path_info ^(.+\.php)(/.+)$;
      # Here we pass php requests to the php7.4-fpm listen socket.  
      # PHP errors are often because this value is not correct.  
      # Verify your php7.4-fpm.sock socket file exists at the below directory
      # and that the php7.4-fpm service is running.
           fastcgi_pass unix:/run/php/php7.4-fpm.sock;
           fastcgi_index index.php;
           include fastcgi_params;
           fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
           fastcgi_intercept_errors off;
           fastcgi_buffer_size 16k;
           fastcgi_buffers 4 16k;
   }

   location ~ /\.ht {
       deny all;
   }

   location = /favicon.ico { access_log off; log_not_found off; }
   location = /robots.txt { access_log off; log_not_found off; }

   access_log /var/log/nginx/ininja.access.log;
   error_log /var/log/nginx/ininja.error.log;

   sendfile off;

  }

  server {
      listen      80;
      server_name invoices.$(hostname -f);
      add_header Strict-Transport-Security max-age=2592000;
      rewrite ^ https://$server_name$request_uri? permanent;
  }
EOF

systemctl stop apache2
systemctl disable apache2
systemctl start nginx
systemctl enable nginx

echo "Invoice Ninja installieren"
echo "**************************************************"
apt install -y unzip
cd /usr/share/nginx
mkdir invoiceninja && cd invoiceninja
wget https://github.com/invoiceninja/invoiceninja/releases/download/v5.4.8/invoiceninja.zip
unzip invoiceninja.zip

#chown www-data:www-data /var/www/invoice-ninja/ -R
#chmod 755 /var/www/invoice-ninja/storage/ -R


clear
echo "*******************************************************************************************"
echo "Server wurde vorbereitet. Bitte ueber das Web das Setup starten"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/ oder http://invoice.$(hostname -f)"
