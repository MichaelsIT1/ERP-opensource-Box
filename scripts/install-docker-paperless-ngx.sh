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

echo "paperless ngx installieren"
echo "*******************************"
bash -c "$(curl -L https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh)"

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
http://\4:7880

EOF

#CLEAR

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:7880/"
echo "*************************************************************"
