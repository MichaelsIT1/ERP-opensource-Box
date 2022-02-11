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

apt-get -y install ntp postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo curl

sleep 3

echo "ISP-Config wird installiert"
echo "**************************************************"

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mysql_secure_installation
                    # current root password (emtpy after installation)
        y           # Set root password?
        ispconfig   # new root password
        ispconfig   # new root password         y          
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
sed -i "s|#  -o 'smtpd_client_restrictions=$mua_client_restrictions'|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf

sleep 3
sed -i "s|#smtps     inet  n       -       y       -       -       smtpd|smtps     inet  n       -       y       -       -       smtpd|g" /etc/postfix/master.cf
sed -i "s|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|g" /etc/postfix/master.cf
sed -i "s|#  -o 'smtpd_client_restrictions=$mua_client_restrictions'|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|g" /etc/postfix/master.cf
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



echo "**************************************************************************"
echo "weiter gehts mit dem Browser. Gehen Sie auf https://$IP:8080"
echo "**************************************************************************"
