#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "Kivitendo installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install  apache2 libarchive-zip-perl libclone-perl \
libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
librose-db-perl librose-object-perl libsort-naturally-perl \
libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
libimage-info-perl libgd-gd2-perl libapache2-mod-fcgid \
libfile-copy-recursive-perl postgresql libalgorithm-checkdigits-perl \
libcrypt-pbkdf2-perl git libcgi-pm-perl libtext-unidecode-perl libwww-perl \
postgresql-contrib poppler-utils libhtml-restrict-perl \
libdatetime-set-perl libset-infinite-perl liblist-utilsby-perl \
libdaemon-generic-perl libfile-flock-perl libfile-slurp-perl \
libfile-mimeinfo-perl libpbkdf2-tiny-perl libregexp-ipv6-perl \
libdatetime-event-cron-perl libexception-class-perl \
libxml-libxml-perl libtry-tiny-perl libmath-round-perl \
libimager-perl libimager-qrcode-perl librest-client-perl libipc-run-perl \
libencode-imaputf7-perl libmail-imapclient-perl libuuid-tiny-perl -y

# Latex-Installation
echo "Latex wird installiert."
apt-get install -y texlive-binaries texlive-latex-recommended texlive-fonts-recommended \
texlive-lang-german dvisvgm fonts-lmodern fonts-texgyre libptexenc1 libsynctex2 \
libteckit0 libtexlua53 libtexluajit2 libzzip-0-13 lmodern tex-common tex-gyre \
texlive-base latexmk texlive-latex-extra

# 1. PostgreSQL stoppen
systemctl stop postgresql  # Oder: service postgresql stop

# 2. Alten Cluster löschen (Achtung: löscht ALLE Datenbanken!)
rm -rf /var/lib/postgresql/17/main  # Ersetze <VERSION> durch deine Version, z.B. 14 oder 16
# Finde die Version mit: psql --version oder dpkg -l | grep postgresql

# 3. Neuen Cluster mit UTF8 anlegen (wichtig: --locale und --encoding explizit!)
su - postgres -c "initdb -D /var/lib/postgresql/17/main --locale=de_DE.UTF-8 --encoding=UTF8"

# Oder, falls de_DE.UTF-8 nicht verfügbar ist, nutze en_US.UTF-8 oder C.UTF-8:
# su - postgres -c "initdb -D /var/lib/postgresql/<VERSION>/main --locale=C.UTF-8 --encoding=UTF8"

# 4. PostgreSQL starten
systemctl start postgresql

# 5. Überprüfen (sollte jetzt UTF8 zeigen)
psql -U postgres -c "SHOW SERVER_ENCODING;"  # Sollte UTF8 ausgeben
psql -U postgres -c "\l"  # Encoding für template1/template0 ist jetzt UTF8














# 4. kivitendo DB-User und Auth-DB anlegen
su - postgres -c "psql" <<EOF
\\set ON_ERROR_STOP on
DROP DATABASE IF EXISTS kivitendo_auth;
DROP USER IF EXISTS kivitendo;
CREATE USER kivitendo WITH PASSWORD kividento CREATEDB;
CREATE DATABASE kivitendo_auth ENCODING 'UTF8' OWNER kivitendo;
GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO kivitendo;
EOF

cd /var/www/
git clone https://github.com/kivitendo/kivitendo-erp.git

cd kivitendo-erp/
git checkout $(git tag -l | egrep -ve "(alpha|beta|rc)" | tail -1)
chown -R www-data: /var/www/kivitendo-erp

cat <<EOL > /etc/apache2/sites-available/kivitendo.apache2.conf
AddHandler fcgid-script .fpl
AliasMatch ^/kivitendo/[^/]+\.pl /var/www/kivitendo-erp/dispatcher.fcgi
Alias       /kivitendo/          /var/www/kivitendo-erp/
<Directory /var/www/kivitendo-erp>
  AllowOverride All
  Options ExecCGI Includes FollowSymlinks
  AddHandler cgi-script .py
  DirectoryIndex login.pl
  AddDefaultCharset UTF-8
  Require all granted
</Directory>
<Directory /var/www/kivitendo-erp/users>
  Require all denied
</Directory>
EOL

ln -sf /etc/apache2/sites-available/kivitendo.apache2.conf /etc/apache2/sites-enabled/kivitendo.apache2.conf
service apache2 restart

echo "config/kivitendo.conf erzeugen"
cp /var/www/kivitendo-erp/config/kivitendo.conf.default /var/www/kivitendo-erp/config/kivitendo.conf
sed -i "s/admin_password.*$/admin_password = 12345" /var/www/kivitendo-erp/config/kivitendo.conf
sed -i "s/password =$/password = 12345" /var/www/kivitendo-erp/config/kivitendo.conf

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
\4\/kivitendo/

EOF

# Als postgres-Systemuser wechseln und Passwort richtig setzen
su - postgres -c "psql" <<EOF
ALTER ROLE postgres WITH PASSWORD 'kivitendo';
\q
EOF


echo "*******************************************************************************************"
echo "kivitendo erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/kivitendo/"
echo "Adminpasswort: admin123
echo "**************************************************************************"


mobil: 0171 / 90 28 930 
e-mail: mspoor@mspoor.de
