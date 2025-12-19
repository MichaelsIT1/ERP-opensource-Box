#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.

# Doku
# https://github.com/andreklug/docspell-debian

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

apt update && apt dist-upgrade -y
sleep 5

apt install docker.io docker-compose git ca-certificates curl gnupg lsb-release -y
sleep 5
clear

echo "docspell installieren"
echo "*******************************"
git clone https://github.com/eikek/docspell
cd docspell/docker/docker-compose
docker-compose up -d

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
http://\4:7880

EOF

CLEAR

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:7880/"
echo "*************************************************************"
