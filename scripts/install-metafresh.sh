#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu in einer VM. Läuft bei mir nicht im LXC-Container
# https://docs.metasfresh.org/installation_collection/DE/Wie_installiere_ich_den_metasfresh_Stack_mit_Docker.html

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)
clear
echo "metafresh installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
echo
echo "Docker wird installiert"
echo "**************************************************"
apt install docker docker.io docker-compose git ca-certificates curl gnupg lsb-release -y
echo
sleep 5
echo "metafresh image herunterladen"
echo "********************************"
cd /root/
git clone https://github.com/metasfresh/metasfresh-docker.git
cd metasfresh-docker/
echo
sleep 2

sed -i "s|#environment|environment|g" docker-compose.yml #environment auskommentieren
sed -i "s|#- WEBAPI_URL=http://example.com:8080|- WEBAPI_URL=http://$(hostname -f)|g" docker-compose.yml #hostname eintragen

sleep 2
echo "Container bauen"
echo "***********************************************************"
docker-compose build
sleep 5
docker-compose up -d

echo "*******************************************************************************************"
echo "metafreh installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/"
echo "**************************************************************************"
