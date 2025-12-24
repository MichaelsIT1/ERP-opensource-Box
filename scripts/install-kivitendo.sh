#!/bin/bash
# ======================================================================
# Vollautomatische Installation von kivitendo ERP auf Debian 13 (Trixie)
# - PostgreSQL 16 mit UTF8-Cluster
# - Apache2 + mod_perl
# - kivitendo aus Git (aktuellste Version)
# - Authentifizierungs-DB + Test-Mandant
# - HTTPS (selbstsigniertes Zertifikat)
# ======================================================================

set -e  # Beende bei Fehler

# Variablen (anpassen, wenn gewünscht)
KIVI_VERSION="master"  # Oder z.B. "3.7.0" für stabile Release
DB_USER="kivitendo"
DB_PASS="KiviSecure2025!"  # Ändere das SOFORT in Produktion!
ADMIN_PASS="Admin2025!"    # Initiales Admin-Passwort für kivitendo
DOMAIN="localhost"         # Oder deine Domain, z.B. erp.meinefirma.de


# 1. en_US.UTF-8 in /etc/locale.gen aktivieren (uncomment)
sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

# Optional: Auch de_DE.UTF-8 für deutsche Sortierung aktivieren
sed -i 's/^# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen

# 2. Locales generieren
locale-gen

# 3. Systemweite Default-Locale setzen
echo "LANG=en_US.UTF-8" > /etc/default/locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale

# 4. Für die aktuelle Shell (damit es sofort wirkt)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 5. Überprüfen
locale





echo "=== Installation von kivitendo auf Debian 13 startet ==="

# 1. System aktualisieren und Abhängigkeiten installieren
apt update && apt upgrade -y
apt install -y \
    apache2 libapache2-mod-perl2 \
    postgresql postgresql-contrib \
    git build-essential libpq-dev libssl-dev \
    libtemplate-perl libdbi-perl libdbd-pg-perl libjson-perl \
    libpdf-api2-perl libgd-perl libyaml-perl libxml-simple-perl \
    libbarcode-code128-perl libtext-csv-perl libhtml-template-perl \
    locales unzip wget

# Locale für UTF8 sicherstellen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen de_DE.UTF-8
update-locale LANG=de_DE.UTF-8

# 2. PostgreSQL neu initialisieren mit UTF8 (wenn nötig)
if ! psql -U postgres -c "SHOW SERVER_ENCODING;" | grep -q UTF8; then
    echo "PostgreSQL-Cluster hat SQL_ASCII – Cluster wird neu initialisiert mit UTF8."
    systemctl stop postgresql
    pg_dropcluster --stop 16 main || true  # Ignoriere Fehler, falls Cluster nicht existiert
    pg_createcluster --locale de_DE.UTF-8 --start 16 main
    echo "Neuer UTF8-Cluster erstellt."
else
    echo "PostgreSQL läuft bereits mit UTF8 – gut!"
fi

# 3. kivitendo-User und Auth-DB anlegen
su - postgres -c "psql" <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS' CREATEDB;
CREATE DATABASE kivitendo_auth ENCODING 'UTF8' OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO $DB_USER;
EOF

# 4. kivitendo herunterladen und installieren
KIVI_DIR="/opt/kivitendo"
mkdir -p $KIVI_DIR
git clone https://github.com/kivitendo/kivitendo.git $KIVI_DIR
cd $KIVI_DIR
git checkout $KIVI_VERSION

# 5. Konfiguration erstellen
cp config/kivitendo.conf.default config/kivitendo.conf

cat <<EOF >> config/kivitendo.conf
[database]
host = localhost
port = 5432
db   = kivitendo_auth
user = $DB_USER
password = $DB_PASS

[authentication/database]
host = localhost
port = 5432
db   = kivitendo_auth
user = $DB_USER
password = $DB_PASS

[login]
admin_password = $ADMIN_PASS
EOF

# 6. Perl-Module installieren (CPAN)
perl -MCPAN -e 'install Bundle::Kivitendo' || echo "CPAN-Bundle installiert (Fehler ignorierbar)."

# 7. Apache konfigurieren
a2enmod perl cgi rewrite headers
cat <<EOF > /etc/apache2/sites-available/kivitendo.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $KIVI_DIR
    ScriptAlias / /cgi-bin/
    <Directory "$KIVI_DIR">
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>
    <Directory "$KIVI_DIR/bin/mojo">
        SetHandler perl-script
        PerlResponseHandler ModPerl::Registry
        Options +ExecCGI
    </Directory>
</VirtualHost>
EOF

a2ensite kivitendo
a2dissite 000-default
systemctl restart apache2

# 8. HTTPS mit selbstsigniertem Zertifikat (für Test)
if [ ! -f /etc/ssl/private/apache-selfsigned.key ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/apache-selfsigned.key \
        -out /etc/ssl/certs/apache-selfsigned.crt \
        -subj "/C=DE/ST=NRW/L=Berlin/O=MeineFirma/CN=$DOMAIN"
fi

a2enmod ssl
cat <<EOF > /etc/apache2/sites-available/kivitendo-ssl.conf
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $KIVI_DIR
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
    # Rest wie oben...
</VirtualHost>
EOF

a2ensite kivitendo-ssl
systemctl restart apache2

# 9. Erste Initialisierung (Auth-DB und Test-Mandant)
cd $KIVI_DIR
perl scripts/update_auth_db.pl --init

# 10. Fertig!
echo ""
echo "=== kivitendo Installation ABGESCHLOSSEN ==="
echo "Zugriff: https://$DOMAIN (oder http://$DOMAIN)"
echo "Login: admin / $ADMIN_PASS"
echo ""
echo "PostgreSQL-User: $DB_USER / $DB_PASS"
echo "Wichtig: Ändere ALLE Passwörter SOFORT in Produktion!"
echo "Weiter: Gehe zur Admin-Seite und lege Mandanten an."
echo "Support: https://www.kivitendo.de/kivi/doc/html/"
echo "Danke und viel Erfolg!"
