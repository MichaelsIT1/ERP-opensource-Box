#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Ubuntu im LXC Container
# https://docs.portainer.io/v/ce-2.9/start/install/server/docker/linux

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "portainer installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update && apt dist-upgrade -y
sleep 5
echo
echo "Docker wird installiert"
echo "**************************************************"
apt install docker docker-compose git ca-certificates curl gnupg lsb-release -y
docker volume create portainer_data
sleep 5

# Portainer herunterladen und starten
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
sleep 10
clear
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:9000/"
echo "*************************************************************"
