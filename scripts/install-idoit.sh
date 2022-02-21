#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "i-doit installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem debian wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install apache2 libapache2-mod-php mariadb-client mariadb-server php php-bcmath php-cli php-common php-curl php-gd php-imagick php-json php-ldap php-mbstring php-memcached php-mysql php-pgsql php-soap php-xml php-zip memcached unzip moreutils -y
echo

tee /etc/php/7.4/mods-available/i-doit.ini >/dev/null <<EOF
allow_url_fopen = Yes
file_uploads = On
magic_quotes_gpc = Off
max_execution_time = 300
max_file_uploads = 42
max_input_time = 60
max_input_vars = 10000
memory_limit = 256M
post_max_size = 128M
register_argc_argv = On
register_globals = Off
short_open_tag = On
upload_max_filesize = 128M
display_errors = Off
display_startup_errors = Off
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
log_errors = On
default_charset = "UTF-8"
default_socket_timeout = 60
date.timezone = Europe/Berlin
session.gc_maxlifetime = 604800
session.cookie_lifetime = 0
mysqli.default_socket = /var/run/mysqld/mysqld.sock
EOF


a2enmod rewrite

phpenmod i-doit
phpenmod memcached
systemctl restart apache2.service


a2dissite 000-default


tee /etc/apache2/sites-available/i-doit.conf >/dev/null <<EOF
<VirtualHost *:80>
        ServerAdmin i-doit@example.net
 
        DocumentRoot /var/www/html/
        <Directory /var/www/html/>
                AllowOverride All
                Require all granted
        </Directory>
 
        LogLevel warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF



a2ensite i-doit
a2enmod rewrite
systemctl restart apache2.service







############# Datenbank erzeugen #########################
 mysql -u root <<EOF
        CREATE DATABASE idoit;
        CREATE USER 'idoit'@'localhost' IDENTIFIED BY 'idoit';
        GRANT ALL PRIVILEGES ON idoit . * TO 'idoit'@'localhost';
        FLUSH PRIVILEGES;
EOF

 # automatische Installation
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        open3a     # new root password
        open3a     # new root password         
        y           # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF


echo "i-doit herunterladen"
echo "********************************"
cd /root/
wget https://sourceforge.net/projects/i-doit/files/latest/download

#mkdir /var/www/html/idoit/
mv download /var/www/html/
cd /var/www/html/idoit/
unzip download










echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/
echo
       
# Rechte setzen
 # chmod 777 specifics/
 # chmod 777 system/Backup/

systemctl restart apache2

echo "*******************************************************************************************"
echo "iTop erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/idoit"
echo "Zugangsdaten: Host: localhost, Benutzer: idoit, Passwort: idoit, Datenbank: idoit, Passwort: idoit"
echo "**************************************************************************"
