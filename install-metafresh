#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu im LXC Container
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
apt install docker.io docker-compose git -y
echo
echo "metafresh image herunterladen"
echo "********************************"
git clone https://github.com/metasfresh/metasfresh-docker.git
cd metasfresh-docker/
echo
echo "Container bauen"
echo "***********************************************************"
docker-compose build
docker-compose up -d
echo "*******************************************************************************************"
echo "metafreh installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/"
echo "**************************************************************************"
