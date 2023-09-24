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

apt --no-install-recommends install ca-certificates curl python3 python3-dev libcurl4-openssl-dev gcc libssl-dev
sleep 5

curl -sSfO 'https://bootstrap.pypa.io/get-pip.py'
sleep 5
python3 get-pip.py
sleep 5
rm get-pip.py

python3 -m pip install 'https://github.com/motioneye-project/motioneye/archive/dev.tar.gz'

motioneye_init

pipx ensurepath

systemctl stop motioneye
python3 -m pip install --upgrade --force-reinstall --no-deps 'https://github.com/motioneye-project/motioneye/archive/dev.tar.gz'
systemctl start motioneye












sleep 5
mkdir -p /etc/motioneye
cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf
 
mkdir -p /var/lib/motioneye
 
cp /usr/local/share/motioneye/extra/motioneye.systemd-unit-local /etc/systemd/system/motioneye.service
systemctl daemon-reload
systemctl enable motioneye
systemctl start motioneye
 
usr/local/bin/pip2 install motioneye --upgrade

clear
echo "*******************************************************************************************"
echo "motioneye erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:8765"
echo "Login: username: admin passwort: "
echo "**************************************************************************"
