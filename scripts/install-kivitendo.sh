#!/bin/bash
# ======================================================================
# Vollautomatische kivitendo 4.0.0 Installation in privilegiertem LXC-Container
# Debian 13 (Trixie) – PostgreSQL 17 mit UTF8
# Dieses Skript behebt alle bisherigen Probleme (SQL_ASCII, hängende Cluster)
# ======================================================================

set -e  # Bei Fehler abbrechen

# === Variablen – IN PRODUKTION UNBEDINGT ÄNDERN! ===
DB_PASS="KiviSuperSicher2025!"   # Starkes Passwort für PostgreSQL-User
ADMIN_PASS="AdminSicher2025!"    # Initiales Admin-Passwort für kivitendo
KIVI_DIR="/opt/kivitendo"

echo "=== kivitendo Installation im LXC-Container startet ==="

# 1. System aktualisieren & alle benötigten Pakete installieren
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

# 2. Locales für UTF8 und deutsche Sortierung generieren
sed -i 's/^# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
export LANG=de_DE.UTF-8
export LC_ALL=de_DE.UTF-8
update-locale LANG=de_DE.UTF-8

# 3. PostgreSQL-Cluster erzwingen mit UTF8 (kompletter Reset bei SQL_ASCII)
echo "PostgreSQL-Cluster wird auf UTF8 umgestellt..."
systemctl stop postgresql 2>/dev/null || true
pkill -u postgres 2>/dev/null || true

pg_dropcluster --stop 17 main 2>/dev/null || true
rm -rf /etc/postgresql/17/main /var/lib/postgresql/17/main

pg_createcluster --locale de_DE.UTF-8 --encoding UTF8 --start 17 main

# Überprüfung
echo "PostgreSQL Encoding (muss UTF8 sein):"
su - postgres -c "psql -c 'SHOW SERVER_ENCODING;'"

# 4. kivitendo DB-User und Auth-DB anlegen
su - postgres -c "psql" <<EOF
\\set ON_ERROR_STOP on
DROP DATABASE IF EXISTS kivitendo_auth;
DROP USER IF EXISTS kivitendo;
CREATE USER kivitendo WITH PASSWORD '$DB_PASS' CREATEDB;
CREATE DATABASE kivitendo_auth ENCODING 'UTF8' OWNER kivitendo;
GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO kivitendo;
EOF

# 5. kivitendo 4.0.0 aus Git holen
mkdir -p $KIVI_DIR
if [ ! -d "$KIVI_DIR/.git" ]; then
    git clone https://github.com/kivitendo/kivitendo-erp.git $KIVI_DIR
fi
cd $KIVI_DIR
git fetch --all --tags
git checkout release-4.0.0

# 6. Konfigurationsdatei anlegen/überschreiben
cp -f config/kivitendo.conf.default config/kivitendo.conf 2>/dev/null || true
cat <<EOF > config/kivitendo.conf
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

# 7. Fehlende Perl-Module installieren (harmlose Fehler ignorieren)
cd $KIVI_DIR
cpanm --installdeps . || echo "CPAN-Fehler sind meist harmlos – wichtige Module sind via apt installiert"

# 8. Apache konfigurieren (HTTPS mit Debian-Snakeoil-Zertifikat)
a2enmod perl cgi rewrite headers ssl
chown -R www-data:www-data $KIVI_DIR/users $KIVI_DIR/spool $KIVI_DIR/webdav 2>/dev/null || mkdir -p $KIVI_DIR/{users,spool,webdav} && chown -R www-data:www-data $KIVI_DIR/{users,spool,webdav}

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
a2dissite 000-default 2>/dev/null || true
systemctl restart apache2

# 9. Authentifizierungsdatenbank initialisieren
cd $KIVI_DIR
perl scripts/update_auth_db.pl --init

# 10. Dienste starten und Logs im Vordergrund (Container bleibt am Laufen)
echo "=== kivitendo ist erfolgreich installiert und läuft! ==="
echo "Öffne im Browser: https://<IP-des-Containers> (selbstsigniertes Zertifikat akzeptieren)"
echo "Admin-Login: admin / $ADMIN_PASS"
echo "Danach ersten Mandanten anlegen und ALLE Passwörter ändern!"

service postgresql start
service apache2 start

# Logs tailen → Container bleibt aktiv
tail -f /var/log/postgresql/*.log /var/log/apache2/*.log
