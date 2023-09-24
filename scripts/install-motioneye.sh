#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 12 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
################################ Update your Debian Installation  ###################################################

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y

apt --no-install-recommends install ca-certificates curl python3 python3-dev libcurl4-openssl-dev gcc libssl-dev -y
sleep 5
#apt install python3-pip -y

rm /usr/lib/python3.11/EXTERNALLY-MANAGED
sleep 5

# PIP installieren
curl -sSfO 'https://bootstrap.pypa.io/get-pip.py'
sleep 5
python3 get-pip.py
sleep 5
rm get-pip.py

sleep 5
python3 -m pip install 'https://github.com/motioneye-project/motioneye/archive/dev.tar.gz'
sleep 5
/usr/local/bin/motioneye_init

# Upgrade
sleep 40
systemctl stop motioneye
python3 -m pip install --upgrade --force-reinstall --no-deps 'https://github.com/motioneye-project/motioneye/archive/dev.tar.gz'
systemctl start motioneye

# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
\4\:8765
Login: username: admin passwort: 

EOF

clear
echo "*******************************************************************************************"
echo "motioneye erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:8765"
echo "Login: username: admin passwort: "
echo "**************************************************************************"
