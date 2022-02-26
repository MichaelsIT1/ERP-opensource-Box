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
apt -y install sudo curl patch unzip bzip2 p7zip p7zip-full unrar lrzip binutils vim expect
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

 #php -q install.php



ISPCONFIG_INSTALL=$(expect -c "
# This Expect script was generated by autoexpect on Sat Feb 26 22:36:51 2022
# Expect and autoexpect were both written by Don Libes, NIST.
#
# Note that autoexpect does not guarantee a working script.  It
# necessarily has to guess about certain things.  Two reasons a script
# might fail are:
#
# 1) timing - A surprising number of programs (rn, ksh, zsh, telnet,
# etc.) and devices discard or ignore keystrokes that arrive "too
# quickly" after prompts.  If you find your new script hanging up at
# one spot, try adding a short sleep just before the previous send.
# Setting "force_conservative" to 1 (see below) makes Expect do this
# automatically - pausing briefly before sending each character.  This
# pacifies every program I know of.  The -c flag makes the script do
# this in the first place.  The -C flag allows you to define a
# character to toggle this mode off and on.

set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasn't run conservatively originally
if {$force_conservative} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}

#
# 2) differing output - Some programs produce different output each time
# they run.  The "date" command is an obvious example.  Another is
# ftp, if it produces throughput statistics at the end of a file
# transfer.  If this causes a problem, delete these patterns or replace
# them with wildcards.  An alternative is to use the -p flag (for
# "prompt") which makes Expect only look for the last line of output
# (i.e., the prompt).  The -P flag allows you to define a character to
# toggle this mode off and on.
#
# Read the man page for more info.
#
# -Don


set timeout -1
spawn php -q install.php
match_max 100000
expect -exact "\r
\r
--------------------------------------------------------------------------------\r
 _____ ___________   _____              __ _         ____\r
|_   _/  ___| ___ \\ /  __ \\            / _(_)       /__  \\\r
  | | \\ `--.| |_/ / | /  \\/ ___  _ __ | |_ _  __ _    _/ /\r
  | |  `--. \\  __/  | |    / _ \\| '_ \\|  _| |/ _` |  |_ |\r
 _| |_/\\__/ / |     | \\__/\\ (_) | | | | | | | (_| | ___\\ \\\r
 \\___/\\____/\\_|      \\____/\\___/|_| |_|_| |_|\\__, | \\____/\r
                                              __/ |\r
                                             |___/ \r
--------------------------------------------------------------------------------\r
\r
\r
>> Initial configuration  \r
\r
Operating System: Debian 11.0 (Bullseye) or compatible\r
\r
    Following will be a few questions for primary configuration so be careful.\r
    Default values are in \[brackets\] and can be accepted with <ENTER>.\r
    Tap in \"quit\" (without the quotes) to stop the installer.\r
\r
\r
Select language (en,de) \[en\]: "
send -- "de\r"
expect -exact "de\r
\r
Installation mode (standard,expert) \[standard\]: "
send -- "\r"
expect -exact "\r
\r
Full qualified hostname (FQDN) of the server, eg server1.domain.tld  \[ispconfig-test.spoor.local\]: "
send -- "\r"
expect -exact "\r
\r
MySQL server hostname \[localhost\]: "
send -- "\r"
expect -exact "\r
\r
MySQL server port \[3306\]: "
send -- "\r"
expect -exact "\r
\r
MySQL root username \[root\]: "
send -- "\r"
expect -exact "\r
\r
MySQL root password \[\]: "
send -- "\r"
expect -exact "\r
\r
MySQL database to create \[dbispconfig\]: "
send -- "\r"
expect -exact "\r
\r
MySQL charset \[utf8\]: "
send -- "\r"
expect -exact "\r
\r
Configuring Postgrey\r
Configuring Postfix\r
Generating a RSA private key\r
..........................++++\r
................................................................................++++\r
writing new private key to 'smtpd.key'\r
-----\r
You are about to be asked to enter information that will be incorporated\r
into your certificate request.\r
What you are about to enter is what is called a Distinguished Name or a DN.\r
There are quite a few fields but you can leave some blank\r
For some fields there will be a default value,\r
If you enter '.', the field will be left blank.\r
-----\r
Country Name (2 letter code) \[AU\]:"
send -- "DE\r"
expect -exact "DE\r
State or Province Name (full name) \[Some-State\]:"
send -- "\r"
expect -exact "\r
Locality Name (eg, city) \[\]:"
send -- "Berlin\r"
expect -exact "Berlin\r
Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:"
send -- "\r"
expect -exact "\r
Organizational Unit Name (eg, section) \[\]:"
send -- "IT\r"
expect -exact "IT\r
Common Name (e.g. server FQDN or YOUR name) \[\]:"
send -- "ispconfig-test.spoor.local\r"
expect -exact "ispconfig-test.spoor.local\r
Email Address \[\]:"
send -- "test@test.de"
expect -exact "
send -- ""
expect -exact "
send -- "öoc"
expect -exact "
send -- ""
expect -exact "
send -- ""
expect -exact "
send -- "local\r"
expect -exact "local\r
problems making Certificate Request\r
140661182383424:error:0D07A07C:asn1 encoding routines:ASN1_mbstring_ncopy:illegal characters:../crypto/asn1/a_mbstr.c:115:\r
\[INFO\] service Mailman not detected\r
Configuring Dovecot\r
Creating new DHParams file, this takes several minutes. Do not interrupt the script.\r
\[INFO\] service Spamassassin not detected\r
\[INFO\] service Amavisd not detected\r
Configuring Rspamd\r
chgrp: cannot access '/etc/rspamd/local.d/worker-controller.inc': No such file or directory\r
chmod: cannot access '/etc/rspamd/local.d/worker-controller.inc': No such file or directory\r
\[INFO\] service Getmail not detected\r
\[INFO\] service Jailkit not detected\r
\[INFO\] service pureftpd not detected\r
\[INFO\] service BIND not detected\r
\[INFO\] service MyDNS not detected\r
Configuring Apache\r
Configuring vlogger\r
\[INFO\] service OpenVZ not detected\r
\[INFO\] service Ubuntu Firewall not detected\r
\[INFO\] service Bastille Firewall not detected\r
\[INFO\] service Metronome XMPP Server not detected\r
\[INFO\] service Fail2ban not detected\r
Installing ISPConfig\r
ISPConfig Port \[8080\]: "
send -- "\r"
expect -exact "\r
\r
Admin password \[fcebfad3\]: "
send -- "test\r"
expect -exact "test\r
\r
Re-enter admin password \[\]: "
send -- "test\r"
expect -exact "test\r
\r
Do you want a secure (SSL) connection to the ISPConfig web interface (y,n) \[y\]: "
send -- "\r"
expect -exact "\r
\r
Checking / creating certificate for ispconfig-test.spoor.local\r
Using certificate path /etc/letsencrypt/live/ispconfig-test.spoor.local\r
Server's public ip(s) (95.91.205.32) not found in A/AAAA records for ispconfig-test.spoor.local: \r
Ignore DNS check and continue to request certificate? (y,n) \[n\]: "
send -- "\r"
expect -exact "\r
\r
Could not issue letsencrypt certificate, falling back to self-signed.\r
Generating a RSA private key\r
............................................................................................................................................++++\r
...............................................................................................................++++\r
writing new private key to '/usr/local/ispconfig/interface/ssl/ispserver.key'\r
-----\r
You are about to be asked to enter information that will be incorporated\r
into your certificate request.\r
What you are about to enter is what is called a Distinguished Name or a DN.\r
There are quite a few fields but you can leave some blank\r
For some fields there will be a default value,\r
If you enter '.', the field will be left blank.\r
-----\r
Country Name (2 letter code) \[AU\]:"
send -- "DE\r"
expect -exact "DE\r
State or Province Name (full name) \[Some-State\]:"
send -- "\r"
expect -exact "\r
Locality Name (eg, city) \[\]:"
send -- "Berlin\r"
expect -exact "Berlin\r
Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:"
send -- "\r"
expect -exact "\r
Organizational Unit Name (eg, section) \[\]:"
send -- "IT\r"
expect -exact "IT\r
Common Name (e.g. server FQDN or YOUR name) \[\]:"
send -- "ispconfig-test.spoor.local\r"
expect -exact "ispconfig-test.spoor.local\r
Email Address \[\]:"
send -- "test@test.de\r"
expect -exact "test@test.de\r
Symlink ISPConfig SSL certs to Postfix? (y,n) \[y\]: "
send -- "\r"
expect eof
")

echo "$ISPCONFIG_INSTALL"


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
