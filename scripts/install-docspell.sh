#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "docspell installieren"
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

apt install curl htop zip gnupg2 ca-certificates sudo -y
apt install default-jdk apt-transport-https wget -y
apt install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf -y

echo "SOLR Installation"
echo "**********************************"
cd /root/
wget https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz
tar xzf solr-8.11.2.tgz
bash solr-8.11.2/bin/install_solr_service.sh solr-8.11.2.tgz

systemctl start solr

su solr -c '/opt/solr-8.11.1/bin/solr create -c docspell'

echo "PostgreSQL Installation"
echo "**********************************"
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/postgresql.list'
apt update && apt full-upgrade -y
apt install postgresql-14 -y

sleep 5
sudo su -
su - postgres

psql -U postgres <<EOF
        CREATE USER docspell
        WITH SUPERUSER CREATEDB CREATEROLE
        PASSWORD '123';
        CREATE DATABASE docspelldb WITH OWNER docspell;
EOF

exit
systemctl enable postgresql

echo "scheduled database backup"
echo "**********************************"

echo "Docspell installation"
echo "**********************************"
cd /tmp
rem https://github.com/eikek/docspell/releases/tag/v0.38.0
wget https://github.com/eikek/docspell/releases/download/v0.38.0/docspell-joex_0.38.0_all.deb
wget https://github.com/eikek/docspell/releases/download/v0.38.0/docspell-restserver_0.38.0_all.deb
dpkg -i docspell*

sleep 10

echo "commandline tool dsc"
echo "**********************************"
wget https://github.com/docspell/dsc/releases/download/v0.9.0/dsc_amd64-musl-0.9.0
mv dsc_amd* dsc
chmod +x dsc
mv dsc /usr/bin

echo "Docspell configuration"
echo "**********************************"
rem offen
rem /etc/docspell-joex/docspell-joex.conf
rem /etc/docspell-restserver/docspell-server.conf


systemctl start docspell-restserver
systemctl enable docspell-restserver
systemctl start docspell-joex
systemctl enable docspell-joex











echo "*******************************************************************************************"
echo "dewawi installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:7880/"
