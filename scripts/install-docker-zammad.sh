#!/bin/sh
# Status: Alpha
# DOCKER DEBIAN
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# https://docs.portainer.io/v/ce-2.9/start/install/server/docker/linux

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "Zammad installieren"
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
apt install docker.io docker-compose git ca-certificates curl gnupg lsb-release -y
sleep 5
git clone https://github.com/zammad/zammad-docker-compose.git
sleep 5
cd zammad-docker-compose
docker compose up -d

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
http://\4:8000

EOF

#clear

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:8000/"
echo "*************************************************************"
