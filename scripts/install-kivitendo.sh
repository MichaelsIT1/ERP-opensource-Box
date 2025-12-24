#!/bin/bash
# ======================================================================
# Vollautomatische Installation von kivitendo auf Debian 13 (Trixie)
# Stand: Dezember 2025
# - PostgreSQL 17 (Default auf Debian 13) mit UTF8
# - Apache2 + mod_perl
# - Aktuellste stabile kivitendo-Version aus Git
# - Authentifizierungs-DB + Grundkonfiguration
# - HTTPS mit selbstsigniertem Zertifikat (für Test)
# ======================================================================

set -e  # Skript bei Fehler abbrechen

# === Variablen – BITTE ANPASSEN ===
DB_USER="kivitendo"
DB_PASS="KiviSuperSicher2025!"   # Starkes Passwort wählen!
ADMIN_PASS="AdminSicher2025!"    # Initiales Admin-Passwort für kivitendo
DOMAIN="localhost"               # Oder deine echte Domain/FQDN
KIVI_DIR="/opt/kivitendo"

echo "=== kivitendo Installation auf Debian 13 startet ==="

# 1. System aktualisieren & Abhängigkeiten installieren
apt update && apt upgrade -y
apt install -y \
    apache2 libapache2-mod-perl2 \
    postgresql postgresql-contrib \
    git build-essential libpq-dev libssl-dev \
    libtemplate-perl libdbi-perl libdbd-pg-perl libjson-perl \
    libpdf-api2-perl libgd-perl libyaml-perl libxml-simple-perl \
    libbarcode-code128-perl libtext-csv-perl libhtml-template-perl \
    locales wget unzip cpanminus libconfig-std-perl

apt install libalgorithm-checkdigits-perl libarchive-zip-perl \
    libcryptx-perl libdaemon-generic-perl libdatetime-perl \
    libdatetime-event-cron-perl libdatetime-format-strptime-perl \
    libdatetime-set-perl libexception-class-perl libemail-address-perl \
    libemail-mime-perl libencode-imaputf7-perl libfile-copy-recursive-perl \
    libfile-flock-perl libfile-mimeinfo-perl libhtml-restrict-perl \
    libimage-info-perl libimager-perl libimager-qrcode-perl \
    liblist-utilsby-perl libmath-round-perl libmail-imapclient-perl \
    libpbkdf2-tiny-perl libregexp-ipv6-perl librest-client-perl \
    librose-object-perl librose-db-perl librose-db-object-perl \
    libset-infinite-perl libsort-naturally-perl libtext-unidecode-perl \
    libuuid-tiny-perl libxml-writer-perl poppler-utils -y

# 2. Locales für UTF8 und deutsche Sortierung sicherstellen (verhindert Perl-Warnings)
sed -i 's/^# *\(de_DE.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/default/locale
export LANG=de_DE.UTF-8
export LC_ALL=de_DE.UTF-8
update-locale LANG=de_DE.UTF-8

# 3. PostgreSQL 17 installieren (Default auf Debian 13 → automatisch UTF8-Cluster)
apt install -y postgresql
systemctl enable --now postgresql

# Überprüfung
echo "PostgreSQL-Version und Encoding:"
su - postgres -c "psql -c 'SHOW server_version;'"
su - postgres -c "psql -c 'SHOW SERVER_ENCODING;'"

# 4. kivitendo-Datenbank-User und Auth-DB anlegen
su - postgres -c "psql" <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS' CREATEDB;
CREATE DATABASE kivitendo_auth ENCODING 'UTF8' OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO $DB_USER;
EOF

# 5. kivitendo aus Git holen (aktuelle stabile Version)
mkdir -p $KIVI_DIR
git clone https://github.com/kivitendo/kivitendo-erp.git $KIVI_DIR
cd $KIVI_DIR

# Neueste stabile Release-Tag auswählen (ohne alpha/beta/rc)
LATEST_TAG=$(git tag -l | grep -E '^release-' | grep -vE '(alpha|beta|rc)' | sort -V | tail -1)
git checkout $LATEST_TAG
echo "kivitendo Version: $LATEST_TAG"

# 6. Konfigurationsdatei anlegen
cp config/kivitendo.conf.default config/kivitendo.conf

cat <<EOF >> config/kivitendo.conf

[database]
host     = localhost
port     = 5432
db       = kivitendo_auth
user     = $DB_USER
password = $DB_PASS

[authentication/database]
host     = localhost
port     = 5432
db       = kivitendo_auth
user     = $DB_USER
password = $DB_PASS

[authentication]
admin_password = $ADMIN_PASS

[system]
default_language = de
EOF

# 7. Fehlende Perl-Module über cpanminus installieren
cpanm --installdeps .

# 8. Apache konfigurieren
a2enmod perl cgi rewrite headers ssl
chown -R www-data:www-data $KIVI_DIR/users $KIVI_DIR/spool $KIVI_DIR/webdav 2>/dev/null || true

cat <<EOF > /etc/apache2/sites-available/kivitendo.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $KIVI_DIR

    <Directory "$KIVI_DIR">
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ $KIVI_DIR/
</VirtualHost>
EOF

# HTTPS mit selbstsigniertem Zertifikat
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/kivitendo.key \
    -out /etc/ssl/certs/kivitendo.crt \
    -subj "/C=DE/ST=Deutschland/L=Ort/O=Firma/CN=$DOMAIN"

cat <<EOF > /etc/apache2/sites-available/kivitendo-ssl.conf
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $KIVI_DIR

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/kivitendo.crt
    SSLCertificateKeyFile /etc/ssl/private/kivitendo.key

    <Directory "$KIVI_DIR">
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ $KIVI_DIR/
</VirtualHost>
EOF

a2ensite kivitendo kivitendo-ssl
a2dissite 000-default
systemctl restart apache2

# 9. Auth-DB initialisieren
cd $KIVI_DIR
perl scripts/update_auth_db.pl --init

# 10. Fertig!
echo ""
echo "=== kivitendo erfolgreich installiert! ==="
echo "Zugriff:"
echo "  HTTP:  http://$DOMAIN"
echo "  HTTPS: https://$DOMAIN (selbstsigniertes Zertifikat – im Browser akzeptieren)"
echo ""
echo "Erster Login in der Admin-Oberfläche:"
echo "  Benutzer: admin"
echo "  Passwort: $ADMIN_PASS"
echo ""
echo "Datenbank:"
echo "  User: $DB_USER"
echo "  Passwort: $DB_PASS"
echo "  DB: kivitendo_auth"
echo ""
echo "WICHTIG:"
echo "  - Alle Passwörter sofort ändern!"
echo "  - Für Produktion: Let's Encrypt für echtes HTTPS einrichten"
echo "  - Firewall: Ports 80 und 443 öffnen (z. B. ufw allow 80,443)"
echo "  - Weitere Mandanten im Admin-Bereich anlegen"
echo ""
echo "Dokumentation: https://www.kivitendo.de/kivi/doc/html/"
echo "Viel Erfolg mit kivitendo!"
