#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
# https://www.howtoforge.com/perfect-server-debian-10-buster-apache-bind-dovecot-ispconfig-3-1/

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
################################  5 Update your Debian Installation  ###################################################
# Non-free aktivieren
echo "*****************"
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free
deb http://security.debian.org/debian-security stable/updates main contrib non-free
deb-src http://security.debian.org/debian-security stable/updates main contrib non-free
EOF

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
echo
sleep 3

echo "Install Basics"
echo "**********************************"
apt-get -y install sudo curl patch ntp openssl unzip bzip2 p7zip p7zip-full unrar lrzip gpg binutils
sleep 30


###################  8 Install Postfix, Dovecot, rkhunter #############################
#apt-get -y install postfix postfix-mysql postfix-doc rkhunter dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd
#sleep 30

###### General type of mail configuration: <-- Internet Site
####### System mail name: <-- server1.example.com

################## POSTFIX Mailserver konfiguration ##############################################
#sed -i "s|#submission inet n       -       y       -       -       smtpd|submission inet n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
#sed -i "s|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_client_restrictions=$mua_client_restrictions|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf

#sleep 3
#sed -i "s|#smtps     inet  n       -       y       -       -       smtpd|smtps     inet  n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
#sed -i "s|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
#sed -i "s|#  -o smtpd_client_restrictions=$mua_client_restrictions|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf
#sleep 3
#systemctl restart postfix


################## MARIADB installieren ##############################################
apt-get -y install mariadb-client mariadb-server
sleep 30

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


# Datei /etc/mysql/mariadb.conf.d/50-server.cnf anpassen
sed -i "s|bind-address            = 127.0.0.1|#bind-address            = 127.0.0.1|g" /etc/mysql/mariadb.conf.d/50-server.cnf


# MARIA-DB ROOT PASSWORT SETZEN
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


######### 9 Install Amavisd-new, SpamAssassin, and ClamAV ###############################
echo "Install Amavisd-new, SpamAssassin, and ClamAV"
echo "**********************************************"
apt-get -y install amavisd-new spamassassin clamav clamav-daemon arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl libdbd-mysql-perl postgrey
sleep 30

systemctl stop spamassassin
systemctl disable spamassassin






########### 10 Install Apache Web Server and PHP ##############################
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


echo "Install PHP"
echo "***********"
apt-get -y install php php php-common php-gd php-mysql php-imap php-cli php-cgi php-curl php-intl php-pspell php-sqlite3 php-tidy php-xmlrpc php-xsl php-zip php-mbstring php-soap php-fpm php-opcache php-memcache php-imagick php-pear 
sleep 30
apt -y install php-curl php-mysqli php-mbstring php-php-gettext
sleep 30


##################### 11 Install Let's Encrypt ##################################
curl https://get.acme.sh | sh -s
sleep 30

################### 12 Install Mailman #########################################
apt-get install mailman
#######  Languages to support: <-- en (English)
######## Missing site list <-- Ok
newlist mailman

## NOCH ZU IMPLEMENTIEREN



############### 13 Install PureFTPd and Quota ################################################
#apt-get -y install pure-ftpd-common pure-ftpd-mysql quota quotatool
#sleep 30

#CA erzeugen
#openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048
#sleep 3
#sed -i "s|VIRTUALCHROOT=false|VIRTUALCHROOT=true|g" /etc/default/pure-ftpd-common
#echo 1 > /etc/pure-ftpd/conf/TLS
#mkdir -p /etc/ssl/private/

######################################################
#sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#DE
#Berlin
#10000
#Test-Company
#IT-Test
#test.test.local
#test@test.local
#EOF
##########################################################
#sleep 2

#chmod 600 /etc/ssl/private/pure-ftpd.pem
#systemctl restart pure-ftpd-mysql
#mount -o remount /


#### OFFEN ##########



############ 14 Install BIND DNS Server #####################
apt-get -y install bind9 dnsutils 
apt-get -y install haveged


############### 15 Install Webalizer, AWStats and GoAccess #######################################
#apt-get -y install webalizer awstats geoip-database libclass-dbi-mysql-perl libtimedate-perl
#sed -i "s|MAILTO=root|#MAILTO=root|g" /etc/cron.d/awstats

# GoAcces
#echo "deb https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
#wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/goaccess.gpg add -
#apt-get -y install goaccess



##################### 16 Install Jailkit #########################################
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


############### 17 Install fail2ban and UFW Firewall ######################################

### OFFEN ########



########## 18 Install PHPMyAdmin Database Administration Tool ##################################
apt install -y phpmyadmin






#################### 19 Install RoundCube Webmail (optional) #########################
########### OFFEN ###################################




############# 20 Download ISPConfig 3 #########################
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/



############## 21 Install ISPConfig #####################
php -q install.php



echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "**************************************************************************"
