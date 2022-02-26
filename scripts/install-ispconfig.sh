#!/bin/sh -x
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
# https://www.howtoforge.com/replacing-amavisd-with-rspamd-in-ispconfig/
# Entwicklerseite ISP-Config: https://www.ispconfig.org / https://www.ispconfig.de

# System-Varibale
MAILSERVER=true         #Postfix, Dovecot, Rspamd
ROUNDCUBEMAIL=true
SSL_LETSENCRYPT=false
PureFTPd=false
AWSTATS=true
PHPMYADMIN=true
DNSSERVER=false
FAIL2BAN=false
FIREWALL=false


IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)
HOSTNAME_NAME=$HOSTNAME
HOSTNAME_DNSNAME=$(hostname -f)

MARIADB_PW=ispconfig

clear
echo '###########################################################'
echo '############## ISP-Config wird installiert ################'
echo '###########################################################'

sleep 3

# Shell auf bash stellen
echo "dash dash/sh boolean false" | debconf-set-selections && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
sleep 3

# locale setzen auf de_DE.UTF-8 UTF-8
sed -i "s|# de_DE.UTF-8 UTF-8|de_DE.UTF-8 UTF-8|g" /etc/locale.gen
locale-gen 2>&1 >/dev/null


echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 

# Non-free aktivieren
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free
EOF

clear
echo '############## Betriebssystem wird aktualisiert ################'
apt update -y && apt dist-upgrade -y
echo
sleep 3

echo "Install Basics"
echo "**********************************"
apt -y install sudo curl patch unzip bzip2 p7zip p7zip-full unrar lrzip binutils vim
apt -y install ssh openssh-server lsb-release apt-transport-https ca-certificates wget git gnupg software-properties-common recode
sleep 30



clear
echo "############################################ Install Apache Web Server ##############################"
apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php libapache2-mod-fcgid apache2-suexec-pristine mcrypt imagemagick libruby libapache2-mod-python memcached memcached libapache2-mod-passenger libapache2-reload-perl ca-certificates openssl 
sleep 30
a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers actions proxy_fcgi alias

# Datei /etc/apache2/conf-available/httpoxy.conf erzeugen und bearbeiten
############################################################################
tee /etc/apache2/conf-available/httpoxy.conf >/dev/null <<EOF
<IfModule mod_headers.c>
    RequestHeader unset Proxy early
</IfModule>
EOF

a2enconf httpoxy
systemctl restart apache2




clear
echo "################## MARIADB installieren ##############################################"
apt-get -y install mariadb-client mariadb-server dbconfig-common
sleep 3

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        ispconfig   # new root password
        ispconfig   # new root password
        Y            # Remove anonymous users?
        y           # Disallow root login remotely?
        y           # Remove test database and access to it?
        y           # Reload privilege tables now?
EOF

mysql -u root -e "SET PASSWORD FOR root@'localhost' = PASSWORD('$MARIADB_PW');"

# MariaDB-Passwort setzen / veraltet
#sed -i "s|user     = root|user     = root\npassword = $MARIADB_PW|g" /etc/mysql/debian.cnf

sleep 5

# MariaDB für alle IP-Adressen öffnen
sed -i "s|bind-address            = 127.0.0.1|#bind-address            = 127.0.0.1|g" /etc/mysql/mariadb.conf.d/50-server.cnf

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


systemctl restart mariadb





clear
echo "################## PHP installieren ##############################################"
apt-get -y install php php php-common php-gd php-mysql php-imap php-cli php-cgi php-curl php-intl php-pspell php-sqlite3 php-tidy php-xmlrpc php-xsl php-zip php-mbstring php-soap php-fpm php-opcache php-memcache php-imagick php-pear php-apcu 
sleep 30
apt -y install php-curl php-mysqli php-mbstring php-php-gettext php-bcmath php-gmp php-bz2 php-phpdbg php-xsl
sleep 30

# Zeitzone setzen
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cgi/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/apache2/php.ini









clear
if ($MAILSERVER)
then
echo "############################### Install Postfix, Dovecot, rkhunter #############################"
apt -y install postfix postfix-mysql postfix-doc dovecot-managesieved dovecot-lmtpd dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve
sleep 3

apt -y install software-properties-common dnsutils nomarch cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl libdbd-mysql-perl

#apt -y install postgrey getmail6

a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers actions proxy_fcgi alias




###### General type of mail configuration: <-- Internet Site
####### System mail name: <-- server1.example.com

echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections 2>&1
echo "postfix postfix/mailname string $HOSTNAME_DNSNAME" | debconf-set-selections 2>&1





################## POSTFIX Mailserver konfiguration ##############################################
sed -i "s|#submission inet n       -       y       -       -       smtpd|submission inet n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
sed -i "s|#  -o syslog_name=postfix/submission|   -o syslog_name=postfix/submission|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_tls_security_level=encrypt|   -o smtpd_tls_security_level=encrypt|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_sasl_auth_enable=yes|   -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_client_restrictions=\$mua_client_restrictions|   -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf

sleep 3
sed -i "s|#smtps     inet  n       -       y       -       -       smtpd|smtps     inet  n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
sed -i "s|#  -o syslog_name=postfix/smtps|   -o syslog_name=postfix/smtps|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_tls_wrappermode=yes|   -o smtpd_tls_wrappermode=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_sasl_auth_enable=yes|   -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_client_restrictions=\$mua_client_restrictions|#   -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf
sleep 3


clear
echo "########################################## Install rspamd and ClamAV ###############################"
# Amavisd wird nicht mehr verwendet, SpamAssassin wird auch nicht mehr benötigt.
# ohne rspamd funktioniert der Mailserver nicht

# Amavisd-new is old, rspamd is new
apt-get -y install redis-server lsb-release
apt-get -y install rspamd

sleep 3
# Config rspamd
echo 'servers = "127.0.0.1";' > /etc/rspamd/local.d/redis.conf
echo "nrows = 2500;" > /etc/rspamd/local.d/history_redis.conf 
echo "compress = true;" >> /etc/rspamd/local.d/history_redis.conf
echo "subject_privacy = false;" >> /etc/rspamd/local.d/history_redis.conf
systemctl restart rspamd

# install Clam-AV
apt-get -y install clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract p7zip p7zip-full unrar lrzip apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl libdbd-mysql-perl

# postgrey whitelist blacklist filter
apt -y install postgrey

# rootkithunter rhunter installed
apt -y install rkhunter

sleep 3

freshclam
service clamav-daemon start
fi



systemctl daemon-reload
systemctl restart postfix
sleep 3


clear



clear
if ($SSL_LETSENCRYPT)
then
echo "############################################ Install Let's Encrypt ##################################"

apt-get -y install certbot
sleep 3
fi

############################################## Install Mailman 3 #########################################
# NOT SUPPORTED


clear
if ($PureFTPd)
then
echo "############################################## Install PureFTPd ################################################"
apt-get -y install pure-ftpd-common pure-ftpd-mysql
sleep 3

#CA erzeugen
openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048
sleep 3
sed -i "s|VIRTUALCHROOT=false|VIRTUALCHROOT=true|g" /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

######################################################
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
DE
Berlin
10000
Test-Company
IT-Test
test.test.local
test@test.local
EOF
##########################################################
sleep 2

chmod 600 /etc/ssl/private/pure-ftpd.pem
systemctl restart pure-ftpd-mysql
fi

clear
if ($DNSSERVER)
then
echo "########################################## Install BIND DNS Server #####################"
apt-get -y install bind9 dnsutils
apt-get -y install haveged

##### resolvconf einrichten
echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/head
#resolvconf -u

fi

clear
if ($AWSTATS)
then
echo "####################################### Install AWStats und GoAccess #######################################"
apt-get -y install vlogger awstats geoip-database libclass-dbi-mysql-perl

# GoAcces
apt-get -y install goaccess
fi

clear
####################################### Install Jailkit #########################################
# CHROOT-Umgebung
#apt-get install build-essential autoconf automake libtool flex bison debhelper binutils jailkit

clear
if ($FAIL2BAN)
then
echo "###################################### Install fail2ban ######################################"
# FAIL2BAN
apt-get -y install fail2ban
fi

if ($FIREWALL)
then
echo "###################################### Install UFW Firewall ######################################"
apt-get -y install ufw
fi


clear
if ($PHPMYADMIN)
then
echo "######################################## Install PHPMyAdmin Database Administration Tool ##################################"

echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections 2>&1
echo "phpmyadmin phpmyadmin/app-password-confirm password 'ispconfig'" | debconf-set-selections 2>&1
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections 2>&1
echo "phpmyadmin phpmyadmin/mysql/admin-pass password ispconfig" | debconf-set-selections 2>&1 
echo "phpmyadmin phpmyadmin/mysql/app-pass password ispconfig" | debconf-set-selections 2>&1
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections 2>&1

apt install -y phpmyadmin

# Erzeuge Benutzer fuer phpmyadmin User: pma Passwort: mypasswort
#mysql -u root <<EOF
#        CREATE USER 'pma'@'localhost' IDENTIFIED BY 'mypassword';
#        GRANT ALL PRIVILEGES ON *.* TO 'pma'@'localhost' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
#        FLUSH PRIVILEGES;
#EOF
fi

systemctl restart apache2

clear
if ($ROUNDCUBEMAIL)
then
echo "######################################### Install RoundCube Webmail (optional) #########################"


echo "roundcube-core roundcube/dbconfig-install boolean true" | debconf-set-selections 2>&1
echo "roundcube-core roundcube/database-type select mysql" | debconf-set-selections 2>&1
echo "roundcube-core roundcube/mysql/admin-user string root" | debconf-set-selections 2>&1
echo "roundcube-core roundcube/mysql/admin-pass password ispconfig" | debconf-set-selections 2>&1
echo "roundcube-core roundcube/mysql/app-pass password ispconfig" | debconf-set-selections 2>&1
echo "roundcube-core roundcube/reconfigure-webserver multiselect apache2" | debconf-set-selections 2>&1

apt-get -y install roundcube roundcube-core roundcube-mysql roundcube-plugins roundcube-plugins-extra javascript-common libjs-jquery-mousewheel php-net-sieve

sed -i "s|#    Alias /roundcube /var/lib/roundcube/public_html|    Alias /roundcube /var/lib/roundcube/public_html\n  Alias /webmail /var/lib/roundcube/public_html|g"  /etc/apache2/conf-enabled/roundcube.conf

sed -i "s|\$config\['default_host'\] = '';|\$config\['default_host'\] = 'localhost';|g"  /etc/roundcube/config.inc.php
sed -i "s|\$config\['smtp_server'\] = '';|\$config\['smtp_server'\] = '%h';|g"  /etc/roundcube/config.inc.php

sed -i "s|\$config\['smtp_port'\] = 587;|\$config\['smtp_port'\] = 25;|g"  /etc/roundcube/config.inc.php
fi

# Services restart
systemctl daemon-reload
systemctl restart apache2
systemctl restart mariadb
systemctl restart postfix
systemctl restart dovecot
systemctl restart rspamd

clear
############################################## Download ISPConfig 3 #########################
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/



############################################## Install ISPConfig #####################

 php -q install.php


sleep 5

#clear
echo "**************************************************************************"
echo "ISP-Config: https://$IP:8080"

if ($ROUNDCUBEMAIL)
then
echo "Roundcubemail: http://$IP/webmail"
fi

if ($PHPMYADMIN)
then
echo "phpMyAdmin: http://$IP/phpmyadmin"
fi

if ($MAILSERVER)
then
echo "Rspamd: $IP:8081/rspamd/"
echo "Passwort siehe ISPConfig -> System > Server Config > Mail"
fi

echo "MariaDB-Passwort: $MARIADB_PW"
echo "**************************************************************************"
