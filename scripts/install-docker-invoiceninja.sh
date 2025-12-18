#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.


# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

clear
echo "Invoice Ninja installieren"
echo "*******************************"
git clone https://github.com/invoiceninja/dockerfiles.git -b debian
cd dockerfiles/debian
docker-compose up -d

CLEAR

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP"
echo "Logindaten Benutzername: admin@example.com Passwort: changeme!"
echo "*************************************************************"
