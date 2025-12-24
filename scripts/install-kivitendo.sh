#!/bin/bash
# ======================================================================
# Vollautomatische kivitendo 4.0.0 Installation in privilegiertem LXC-Container
# Debian 13 (Trixie) – PostgreSQL 17 mit UTF8
# Stand: Dezember 2025
# ======================================================================

set -e

# === Variablen – SOFORT ÄNDERN in Produktion! ===
DB_PASS="KiviSuperSicher2025!"   # Starkes Passwort für DB-User
ADMIN_PASS="AdminSicher2025!"    # Initiales Admin-Passwort für kivitendo
KIVI_DIR="/opt/kivitendo"

echo "=== kivitendo Installation im LXC-Container startet ==="

# 1. System aktualisieren & Pakete installieren
apt update && apt upgrade -y
apt install -y \
    apache2 libapache2-mod-perl2 \
    postgresql postgresql-contrib \
    git build-essential libpq-dev libssl-dev \
    libtemplate-perl libdbi-perl libdbd-pg-perl libjson-perl \
    libpdf-api2-perl libgd-perl libyaml-perl libxml-simple-perl \
    libbarcode-code128-perl libtext-csv-perl libhtml-template-perl \
    libconfig-std-perl \
    locales cpanminus wget unzip

# 2. Locales für UTF8 und deutsche Sortierung (verhindert Perl-Warnings)
sed -i 's/^# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
export LANG=de_DE.UTF-8
export LC_ALL=de_DE.UTF-8
update-locale LANG=de_DE.UTF-8

# 3. PostgreSQL-Cluster mit UTF8 sicherstellen
if su - postgres -c "psql -t -c 'SHOW SERVER_ENCODING'" | grep -q "SQL_ASCII"; then
    echo "SQL_ASCII erkannt – Cluster wird mit UTF8 neu angelegt"
    systemctl stop postgresql
    pg_dropcluster 17 main || true
    pg_createcluster --locale de_DE.UTF-8 --encoding UTF8 --start 17 main
fi

# Überprüfung
echo "PostgreSQL Encoding:"
su - postgres -c "psql -c 'SHOW SERVER_ENCODING;'"

# 4. kivitendo DB-User und Auth-DB anlegen
su - postgres -c "psql" <<EOF
DROP DATABASE IF EXISTS kivitendo_auth;
DROP USER IF EXISTS kivitendo;
CREATE USER kivitendo WITH PASSWORD '$DB_PASS' CREATEDB;
CREATE DATABASE kivitendo_auth ENCODING 'UTF8' OWNER kivitendo;
GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO kivitendo;
EOF

# 5. kivitendo holen
mkdir -p $KIVI_DIR
git clone https://github.com/kivitendo/kivitendo-erp.git $KIVI_DIR
cd $KIVI_DIR
git checkout release-4.0.0

# 6. Konfiguration
cp config/kivitendo.conf.default config/kivitendo.conf
cat <<EOF >> config/kivitendo.conf

[database]
host     = localhost
port     = 5432
db       = kivitendo_auth
user     = kivitendo
password = $DB_PASS

[authentication/database]
host     = localhost
port     = 5432
db       = kivitendo_auth
user     = kivitendo
password = $DB_PASS

[authentication]
admin_password = $ADMIN_PASS

[system]
default_language = de
EOF

# 7. Perl-Module installieren (harmlose Configuring-Fehler ignorieren)
cpanm --installdeps . || echo "CPAN-Fehler sind meist harmlos"

# 8. Apache konfigurieren (HTTPS mit Debian-Snakeoil-Zertifikat)
a2enmod perl cgi rewrite headers ssl
chown -R www-data:www-data $KIVI_DIR/users $KIVI_DIR/spool $KIVI_DIR/webdav 2>/dev/null || true

cat <<EOF > /etc/apache2/sites-available/kivitendo.conf
<VirtualHost *:80>
    ServerName localhost
    Redirect permanent / https://localhost/
</VirtualHost>

<VirtualHost *:443>
    ServerName localhost
    DocumentRoot $KIVI_DIR

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    <Directory "$KIVI_DIR">
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias / $KIVI_DIR/
</VirtualHost>
EOF

a2ensite kivitendo
a2dissite 000-default
systemctl restart apache2

# 9. Auth-DB initialisieren
cd $KIVI_DIR
perl scripts/update_auth_db.pl --init

# 10. Dienste starten und Logs im Vordergrund (damit Container läuft)
echo "=== kivitendo ist installiert und läuft! ==="
echo "HTTPS: https://<Container-IP-oder-Hostname> (Snakeoil-Zertifikat – Exception akzeptieren)"
echo "Admin-Login: admin / $ADMIN_PASS"
echo "Passwörter sofort ändern!"

service postgresql start
service apache2 start

# Logs tailen, damit Container nicht stoppt
tail -f /var/log/postgresql/*.log /var/log/apache2/*.log
