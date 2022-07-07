#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

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
echo "PHP wird installiert"
echo "**************************************************"
apt install php7.4 php7.4-{fpm,bcmath,ctype,fileinfo,json,mbstring,pdo,tokenizer,xml,curl,zip,gmp,gd,mysqli} mariadb-server mariadb-client curl git nginx vim composer -y
echo
systemctl enable --now mariadb
 #automatische Installation
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        ninja     # new root password
        ninja     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF
mkdir -p /etc/nginx/cert
openssl req -new -x509 -days 365 -nodes -out /etc/nginx/cert/ninja.crt -keyout /etc/nginx/cert/ninja.key
rm /etc/nginx/sites-enabled/default

tee /etc/nginx/conf.d/invoiceninja.conf >/dev/null <<EOF
  server {
# NOTE That the 'default_server' option is only necessary if this is your primary domain application.
# If you run multiple subdomains from the same host already, remove the 'default_server' option.
   listen       443 ssl http2 default_server;
   listen       [::]:443 ssl http2 default_server;
   server_name  """invoices.example.ca""";
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
   root         /usr/share/nginx/"""invoiceninja"""/public;

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
      server_name """invoices.example.ca""";
      add_header Strict-Transport-Security max-age=2592000;
      rewrite ^ https://$server_name$request_uri? permanent;
  }
