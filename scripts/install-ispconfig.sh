#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 10 (buster) im LXC Container
# https://www.howtoforge.com/ispconfig-autoinstall-debian-ubuntu/

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "ISP-Config installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo

# Non-free aktivieren
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ buster main contrib non-free
deb-src http://deb.debian.org/debian/ buster main contrib non-free
deb http://security.debian.org/debian-security buster/updates main contrib non-free
deb-src http://security.debian.org/debian-security buster/updates main contrib non-free
EOF

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
echo

echo "Install Postfix, Dovecot, MariaDB, rkhunter, and Binutils"
echo ***********************************************************
apt-get -y install ntp postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo curl

sleep 3



sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        n           # Set root password?
        #ispconfig   # new root password
        #ispconfig   # new root password
        Y            # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF

sleep 3

sed -i "s|#submission inet n       -       y       -       -       smtpd|submission inet n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
sed -i "s|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_client_restrictions=$mua_client_restrictions|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf

sleep 3
sed -i "s|#smtps     inet  n       -       y       -       -       smtpd|smtps     inet  n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
sed -i "s|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_client_restrictions=$mua_client_restrictions|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf
sleep 3

systemctl restart postfix

# Datei /etc/mysql/mariadb.conf.d/50-server.cnf anpassen
sed -i "s|bind-address            = 127.0.0.1|#bind-address            = 127.0.0.1|g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Passwort setzen für phpadmin
echo "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root

# MySQL-Passwort auf ispconfig setzen
sed -i "s|password =|password = ispconfig|g" /etc/mysql/debian.cnf

# Datei /etc/security/limits.conf ergaenzen
cp /etc/security/limits.conf /etc/security/limits.conf.orig

tee /etc/security/limits.conf >/dev/null <<EOF
mysql soft nofile 65535
mysql hard nofile 65535
EOF


# Datei /etc/systemd/system/mysql.service.d/limits.conf erzeugen und befuellen
mkdir -p /etc/systemd/system/mysql.service.d/
touch /etc/systemd/system/mysql.service.d/limits.conf

tee /etc/systemd/system/mysql.service.d/limits.conf >/dev/null <<EOF
[Service]
LimitNOFILE=infinity
EOF

sleep 3

systemctl daemon-reload
systemctl restart mariadb

#echo "Install Amavisd-new, SpamAssassin, and ClamAV"
#echo "**********************************************"

#apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract p7zip p7zip-full unrar lrzip apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl libdbd-mysql-perl postgrey

#systemctl stop spamassassin
#systemctl disable spamassassin

echo "Install Apache Web Server and PHP"
echo "**********************************"
apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php php7.3 php7.3-common php7.3-gd php7.3-mysql php7.3-imap php7.3-cli php7.3-cgi libapache2-mod-fcgid apache2-suexec-pristine php-pear mcrypt  imagemagick libruby libapache2-mod-python php7.3-curl php7.3-intl php7.3-pspell php7.3-recode php7.3-sqlite3 php7.3-tidy php7.3-xmlrpc php7.3-xsl memcached php-memcache php-imagick php-gettext php7.3-zip php7.3-mbstring memcached libapache2-mod-passenger php7.3-soap php7.3-fpm php7.3-opcache php-apcu libapache2-reload-perl

a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers actions proxy_fcgi alias

# Datei /etc/apache2/conf-available/httpoxy.conf erzeugen und bearbeiten
tee /etc/apache2/conf-available/httpoxy.conf >/dev/null <<EOF
<IfModule mod_headers.c>
    RequestHeader unset Proxy early
</IfModule>
EOF

a2enconf httpoxy
systemctl restart apache2

echo "Install Let's Encrypt"
echo "**********************"
curl https://get.acme.sh | sh -s

#echo "Install Mailman FEHLER"
#echo "**********************"
#apt -y install mailman

#echo "Install PureFTPd and Quota"
#echo "**********************"
#apt-get -y install pure-ftpd-common pure-ftpd-mysql quota quotatool

#openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048
#sleep 3

#sed -i "s|VIRTUALCHROOT=false|VIRTUALCHROOT=true|g" /etc/default/pure-ftpd-common

#echo 1 > /etc/pure-ftpd/conf/TLS
#mkdir -p /etc/ssl/private/

#sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#DE
#Berlin
#10000
#Test-Company
#IT-Test
#test.test.local
#test@test.local
#EOF

#sleep 2

#chmod 600 /etc/ssl/private/pure-ftpd.pem
#systemctl restart pure-ftpd-mysql
#mount -o remount /

echo "Install BIND DNS Server"
echo "'''''''''''''''''''''''"
apt-get -y install bind9 dnsutils haveged


#echo "Install Webalizer, AWStats and GoAccess"
#echo "****************************************"

#apt-get -y install webalizer awstats geoip-database libclass-dbi-mysql-perl libtimedate-perl

#sed -i "s|MAILTO=root|#MAILTO=root|g" /etc/cron.d/awstats

#echo "deb https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
#wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/goaccess.gpg add -
#apt-get update
#apt-get install goaccess

#echo "Install Jailkit"
#echo "***************"
#apt-get install build-essential autoconf automake libtool flex bison debhelper binutils

#cd /tmp
#wget http://olivier.sessink.nl/jailkit/jailkit-2.20.tar.gz
#tar xvfz jailkit-2.20.tar.gz
#cd jailkit-2.20
#echo 5 > debian/compat
#./debian/rules binary

#cd ..
#dpkg -i jailkit_2.20-1_*.deb
#rm -rf jailkit-2.20*

echo "Install PHPMyAdmin Database Administration Tool"
echo "************************************************"
mkdir /usr/share/phpmyadmin
mkdir /etc/phpmyadmin
mkdir -p /var/lib/phpmyadmin/tmp
chown -R www-data:www-data /var/lib/phpmyadmin
touch /etc/phpmyadmin/htpasswd.setup

cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.tar.gz

tar xfz phpMyAdmin-4.9.0.1-all-languages.tar.gz
mv phpMyAdmin-4.9.0.1-all-languages/* /usr/share/phpmyadmin/
rm phpMyAdmin-4.9.0.1-all-languages.tar.gz
rm -rf phpMyAdmin-4.9.0.1-all-languages

cp /usr/share/phpmyadmin/config.sample.inc.php  /usr/share/phpmyadmin/config.inc.php

sed -i "s|$cfg['blowfish_secret'] =|$cfg['blowfish_secret'] = 'bD3e6wva9fnd93jVsb7SDgeiBCd452Dh'; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */|g" /usr/share/phpmyadmin/config.inc.php

echo "$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" >> /usr/share/phpmyadmin/config.inc.php

tee /etc/apache2/conf-available/phpmyadmin.conf >/dev/null <<EOF
# phpMyAdmin default Apache configuration

Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
 Options FollowSymLinks
 DirectoryIndex index.php

 <IfModule mod_php7.c>
 AddType application/x-httpd-php .php

 php_flag magic_quotes_gpc Off
 php_flag track_vars On
 php_flag register_globals Off
 php_value include_path .
 </IfModule>

</Directory>

# Authorize for setup
<Directory /usr/share/phpmyadmin/setup>
 <IfModule mod_authn_file.c>
 AuthType Basic
 AuthName "phpMyAdmin Setup"
 AuthUserFile /etc/phpmyadmin/htpasswd.setup
 </IfModule>
 Require valid-user
</Directory>

# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/libraries>
 Order Deny,Allow
 Deny from All
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
 Order Deny,Allow
 Deny from All
</Directory>
EOF


a2enconf phpmyadmin
systemctl restart apache2

mysql -u root <<EOF
        CREATE DATABASE phpmyadmin;
        CREATE USER 'pma'@'localhost' IDENTIFIED BY 'mypassword';
        GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
EOF

mysql -u root phpmyadmin < /usr/share/phpmyadmin/sql/create_tables.sql

sed -i "s|// $cfg['Servers'][$i]['controlhost'] = '';|$cfg['Servers'][$i]['controlhost'] = 'localhost';|g"  /usr/share/phpmyadmin/config.inc.php
sed -i "s|// $cfg['Servers'][$i]['controlpass'] = 'pmapass';|$cfg['Servers'][$i]['controlpass'] = 'mypassword';|g"  /usr/share/phpmyadmin/config.inc.php

echo "Download ISPConfig 3"
echo "********************"
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/

echo "Install ISPConfig"
echo "*****************"
php -q install.php





echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "**************************************************************************"
