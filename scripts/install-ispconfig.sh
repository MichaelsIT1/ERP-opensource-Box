#!/bin/sh -x
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
# https://www.howtoforge.com/perfect-server-debian-10-buster-apache-bind-dovecot-ispconfig-3-1/
# https://www.howtoforge.com/tutorial/perfect-server-ubuntu-20.04-with-apache-php-myqsl-pureftpd-bind-postfix-doveot-and-ispconfig/

echo "ISP-Config installieren"
echo "*******************************"

# System-Varibale
MAIL=true
VIRENSCANNER=false
SSL_LETSENCRYPT=true
PureFTPd=false
AWSTATS=true
PHPMYADMIN=false
DNSSERVER=false
FAIL2BAN=false
FIREWALL=false


IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)
HOSTNAME_NAME=$HOSTNAME
HOSTNAME_DNSNAME=$(hostname -f)

MARIADB_PW=ispconfig



sleep 3

# Shell auf bash stellen
echo "dash dash/sh boolean false" | debconf-set-selections && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash 2>&1
sleep 3

# locale setzen auf de_DE.UTF-8 UTF-8
sed -i "s|# de_DE.UTF-8 UTF-8|de_DE.UTF-8 UTF-8|g" /etc/locale.gen
locale-gen


echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 


echo ################################  Update your Debian Installation ###################################################

# Non-free aktivieren
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free
EOF

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt upgrade -y
echo
sleep 3

echo "Install Basics"
echo "**********************************"
apt-get -y install sudo curl patch openssl unzip bzip2 p7zip p7zip-full unrar lrzip gpg binutils software-properties-common vim
sleep 30


##### resolvconf einrichten
#echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/head
#resolvconf -u



############################################ Install Apache Web Server ##############################
echo "Install Apache Web Server"
echo "**********************************"
apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php libapache2-mod-fcgid apache2-suexec-pristine mcrypt imagemagick libruby libapache2-mod-python memcached memcached libapache2-mod-passenger php-apcu libapache2-reload-perl
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





################## MARIADB installieren ##############################################
apt-get -y install mariadb-client mariadb-server
sleep 30


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






################## PHP installieren ##############################################
echo "Install PHP"
echo "***********"
apt-get -y install php php php-common php-gd php-mysql php-imap php-cli php-cgi php-curl php-intl php-pspell php-sqlite3 php-tidy php-xmlrpc php-xsl php-zip php-mbstring php-soap php-fpm php-opcache php-memcache php-imagick php-pear 
sleep 30
apt -y install php-curl php-mysqli php-mbstring php-php-gettext php-bcmath php-gmp php-bz2 php-phpdbg php-xsl
sleep 30

# Zeitzone setzen
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cgi/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/apache2/php.ini










############################### Install Postfix, Dovecot, rkhunter #############################
if ($MAIL)
then
apt-get -y install postfix-mysql postfix-doc postgrey dovecot-managesieved dovecot-lmtpd getmail6 rkhunter dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve
sleep 10


apt-get -y install software-properties-common dnsutils resolvconf nomarch cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl libdbd-mysql-perl


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
systemctl restart postfix
fi


sleep 3

# MariaDB-Passwort setzen
sed -i "s|user     = root|user     = root\npassword = $MARIADB_PW|g" /etc/mysql/debian.cnf

systemctl restart mariadb 
sleep 5

# Datei /etc/mysql/mariadb.conf.d/50-server.cnf anpassen
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

systemctl daemon-reload
systemctl restart mariadb


########################################## Install Amavisd-new, SpamAssassin, and ClamAV ###############################
if ($VIRENSCANNER)
then

echo "Install Amavisd-new, SpamAssassin, and ClamAV"
echo "**********************************************"

apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey


sleep 30

systemctl stop spamassassin
systemctl disable spamassassin

freshclam
service clamav-daemon start
fi




############################################ Install Let's Encrypt ##################################
if ($SSL_LETSENCRYPT)
then
apt-get -y install certbot
sleep 30
fi

############################################## Install Mailman 3 #########################################
# NOT SUPPORTED

############################################## Install PureFTPd ################################################
if ($PureFTPd)
then
apt-get -y install pure-ftpd-common pure-ftpd-mysql
sleep 30

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


########################################## Install BIND DNS Server #####################
if ($DNSSERVER)
then
apt-get -y install bind9 dnsutils 
apt-get -y install haveged
fi

####################################### Install AWStats #######################################
if ($AWSTATS)
then
apt-get -y install vlogger awstats geoip-database libclass-dbi-mysql-perl

# GoAcces
apt-get -y install goaccess
fi


####################################### Install Jailkit #########################################
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


###################################### Install fail2ban and UFW Firewall ######################################
# FAIL2BAN
if ($FAIL2BAN)
then
apt-get -y install fail2ban
fi

# FIREWALL
if ($FIREWALL)
then
apt-get -y install ufw
fi



######################################## Install PHPMyAdmin Database Administration Tool ##################################
if ($PHPMYADMIN)
then
apt install -y phpmyadmin

# Erzeuge Benutzer fuer phpmyadmin
#mysql -u root <<EOF
#        CREATE USER 'pma'@'localhost' IDENTIFIED BY 'mypassword';
#        GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
#        FLUSH PRIVILEGES;
#EOF
fi

systemctl restart apache2


######################################### Install RoundCube Webmail (optional) #########################
if ($MAIL)
then

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
















############################################## Download ISPConfig 3 #########################
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/



############################################## Install ISPConfig #####################
php -q install.php


sleep 5


tee -a /etc/postfix/main.cf >/dev/null <<EOF
smtpd_sender_restrictions = check_sender_access proxy:mysql:/etc/postfix/mysql-virtual_sender.cf, permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_sender, reject_unlisted_sender
#myhostname = $HOSTNAME_NAME
#smtpd_milters = inet:localhost:11332
#non_smtpd_milters = inet:localhost:11332
#milter_protocol = 6
#milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen}
#milter_default_action = accept
EOF

postfix reload
sleep 5












echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "MariaDB-Passwort: $MARIADB_PW"
echo "**************************************************************************"
