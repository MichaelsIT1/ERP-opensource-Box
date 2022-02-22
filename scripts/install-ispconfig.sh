#!/bin/sh
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
AWSTATS=false
PHPMYADMIN=false
DNS-SERVER=false
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
apt-get -y install sudo curl patch openssl unzip bzip2 p7zip p7zip-full unrar lrzip gpg binutils software-properties-common resolvconf
sleep 30


##### resolvconf einrichten
echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/head
resolvconf -u


###################  8 Install Postfix, Dovecot, rkhunter #############################
if ($MAIL)
then
apt-get -y install postfix-mysql postfix-doc postgrey dovecot-managesieved dovecot-lmtpd getmail6 rkhunter dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve
sleep 10

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

if ($VIRENSCANNER)
then
######### 9 Install Amavisd-new, SpamAssassin, and ClamAV ###############################
echo "Install Amavisd-new, SpamAssassin, and ClamAV"
echo "**********************************************"

apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey


sleep 30

systemctl stop spamassassin
systemctl disable spamassassin

freshclam
service clamav-daemon start
fi



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
apt -y install php-curl php-mysqli php-mbstring php-php-gettext php-bcmath php-gmp php-bz2 php-phpdbg php-xsl
sleep 30

# Zeitzone setzen
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cgi/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = Europe/Berlin|g" /etc/php/7.4/apache2/php.ini


##################### 11 Install Let's Encrypt ##################################
if ($SSL_LETSENCRYPT)
then
apt-get -y install certbot
sleep 30
fi

################### 12 Install Mailman 3 #########################################
# NOT SUPPORTED

############### 13 Install PureFTPd ################################################
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


############ 14 Install BIND DNS Server #####################
if ($DNS-SERVER)
then
apt-get -y install bind9 dnsutils 
apt-get -y install haveged
fi

############### 15 Install AWStats #######################################
if ($AWSTATS)
then
apt-get -y install vlogger awstats geoip-database libclass-dbi-mysql-perl

# GoAcces
#echo "deb https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
#wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/goaccess.gpg add -
#apt-get -y install goaccess
fi


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



################ 18 Install PHPMyAdmin Database Administration Tool ##################################
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


#################### 19 Install RoundCube Webmail (optional) #########################
if ($MAIL)
then
apt-get -y install roundcube roundcube-core roundcube-mysql roundcube-plugins roundcube-plugins-extra javascript-common libjs-jquery-mousewheel php-net-sieve

sed -i "s|#    Alias /roundcube /var/lib/roundcube/public_html|    Alias /roundcube /var/lib/roundcube/public_html\n  Alias /webmail /var/lib/roundcube/public_html|g"  /etc/apache2/conf-enabled/roundcube.conf

sed -i "s|\$config\['default_host'\] = '';|\$config\['default_host'\] = 'localhost';|g"  /etc/roundcube/config.inc.php
sed -i "s|\$config\['smtp_server'\] = '';|\$config\['smtp_server'\] = '%h';|g"  /etc/roundcube/config.inc.php

sed -i "s|\$config\['smtp_port'\] = 587;|\$config\['smtp_port'\] = 25;|g"  /etc/roundcube/config.inc.php
fi



mv /etc/postfix/main.cf /etc/postfix/main.cf_original
sleep 3

tee /etc/postfix/main.cf >/dev/null <<EOF
# See /usr/share/postfix/main.cf.dist for a commented, more complete version

smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

alias_maps = hash:/etc/aliases, hash:/var/lib/mailman/data/aliases
alias_database = hash:/etc/aliases, hash:/var/lib/mailman/data/aliases
mydestination = $HOSTNAME_DNSNAME, localhost, localhost.localdomain
relayhost = 
mynetworks = 127.0.0.0/8 [::1]/128
inet_interfaces = all
recipient_delimiter = +

compatibility_level = 2

readme_directory = /usr/share/doc/postfix
html_directory = /usr/share/doc/postfix/html
virtual_alias_domains = proxy:mysql:/etc/postfix/mysql-virtual_alias_domains.cf
virtual_alias_maps = hash:/var/lib/mailman/data/virtual-mailman, proxy:mysql:/etc/postfix/mysql-virtual_forwardings.cf, proxy:mysql:/etc/postfix/mysql-virtual_alias_maps.cf, proxy:mysql:/etc/postfix/mysql-virtual_email2email.cf
virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf
virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf
virtual_mailbox_base = /var/vmail
virtual_uid_maps = proxy:mysql:/etc/postfix/mysql-virtual_uids.cf
virtual_gid_maps = proxy:mysql:/etc/postfix/mysql-virtual_gids.cf
sender_bcc_maps = proxy:mysql:/etc/postfix/mysql-virtual_outgoing_bcc.cf
inet_protocols = all
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_sasl_authenticated_header = yes
smtpd_restriction_classes = greylisting
greylisting = check_policy_service inet:127.0.0.1:10023
smtpd_recipient_restrictions = permit_mynetworks, reject_unknown_recipient_domain, reject_unlisted_recipient, check_recipient_access proxy:mysql:/etc/postfix/mysql-verify_recipients.cf, permit_sasl_authenticated, reject_non_fqdn_recipient, reject_unauth_destination, check_recipient_access proxy:mysql:/etc/postfix/mysql-virtual_recipient.cf, check_recipient_access mysql:/etc/postfix/mysql-virtual_policy_greylist.cf, check_policy_service unix:private/quota-status
smtpd_use_tls = yes
smtpd_tls_security_level = may
smtpd_tls_cert_file = /etc/postfix/smtpd.cert
smtpd_tls_key_file = /etc/postfix/smtpd.key
transport_maps = hash:/var/lib/mailman/data/transport-mailman, proxy:mysql:/etc/postfix/mysql-virtual_transports.cf
relay_domains = proxy:mysql:/etc/postfix/mysql-virtual_relaydomains.cf
relay_recipient_maps = proxy:mysql:/etc/postfix/mysql-virtual_relayrecipientmaps.cf
smtpd_sender_login_maps = proxy:mysql:/etc/postfix/mysql-virtual_sender_login_maps.cf
proxy_read_maps = $local_recipient_maps $mydestination $virtual_alias_maps $virtual_alias_domains $sender_bcc_maps $virtual_mailbox_maps $virtual_mailbox_domains $relay_recipient_maps $relay_domains $canonical_maps $sender_canonical_maps $recipient_canonical_maps $relocated_maps $transport_maps $mynetworks $smtpd_sender_login_maps $virtual_uid_maps $virtual_gid_maps $smtpd_client_restrictions $smtpd_sender_restrictions $smtpd_recipient_restrictions $smtp_sasl_password_maps $sender_dependent_relayhost_maps
smtpd_helo_required = yes
smtpd_helo_restrictions = permit_mynetworks, check_helo_access regexp:/etc/postfix/helo_access, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, check_helo_access regexp:/etc/postfix/blacklist_helo, ,reject_unknown_helo_hostname, permit
smtpd_sender_restrictions = check_sender_access proxy:mysql:/etc/postfix/mysql-virtual_sender.cf, permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_sender, reject_unlisted_sender
smtpd_reject_unlisted_sender = no
smtpd_client_restrictions = check_client_access proxy:mysql:/etc/postfix/mysql-virtual_client.cf, permit_inet_interfaces, permit_mynetworks, permit_sasl_authenticated, reject_rbl_client zen.spamhaus.org, reject_unauth_pipelining , permit
smtpd_etrn_restrictions = permit_mynetworks, reject
smtpd_data_restrictions = permit_mynetworks, reject_unauth_pipelining, reject_multi_recipient_bounce, permit
smtpd_client_message_rate_limit = 100
maildrop_destination_concurrency_limit = 1
maildrop_destination_recipient_limit = 1
virtual_transport = lmtp:unix:private/dovecot-lmtp
header_checks = regexp:/etc/postfix/header_checks
mime_header_checks = regexp:/etc/postfix/mime_header_checks
nested_header_checks = regexp:/etc/postfix/nested_header_checks
body_checks = regexp:/etc/postfix/body_checks
owner_request_special = no
smtp_tls_security_level = dane
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_protocols = !SSLv2,!SSLv3
smtp_tls_protocols = !SSLv2,!SSLv3
smtpd_tls_exclude_ciphers = RC4, aNULL
smtp_tls_exclude_ciphers = RC4, aNULL
smtpd_tls_mandatory_ciphers = medium
tls_medium_cipherlist = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
tls_preempt_cipherlist = yes
address_verify_negative_refresh_time = 60s
enable_original_recipient = no
sender_dependent_relayhost_maps = proxy:mysql:/etc/postfix/mysql-virtual_sender-relayhost.cf
smtp_sasl_password_maps = proxy:mysql:/etc/postfix/mysql-virtual_sender-relayauth.cf, texthash:/etc/postfix/sasl_passwd
smtp_sender_dependent_authentication = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous, noplaintext
smtp_sasl_tls_security_options = noanonymous
smtpd_forbidden_commands = CONNECT,GET,POST,USER,PASS
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
address_verify_sender_ttl = 15686s
smtp_dns_support_level = dnssec
myhostname = $HOSTNAME_DNSNAME
dovecot_destination_recipient_limit = 1
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_milters = inet:localhost:11332
non_smtpd_milters = inet:localhost:11332
milter_protocol = 6
milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen}
milter_default_action = accept
EOF

postfix reload
sleep 5










############# 20 Download ISPConfig 3 #########################
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/



############## 21 Install ISPConfig #####################
php -q install.php


sleep 5















echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "MariaDB-Passwort: $MARIADB_PW"
echo "**************************************************************************"
