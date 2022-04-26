#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container

# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
################################ Update your Debian Installation  ###################################################
# Non-free aktivieren
tee /etc/apt/sources.list.d/ispconfig.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ stable main contrib non-free
deb-src http://deb.debian.org/debian/ stable main contrib non-free
EOF

echo "Betriebssystem wird aktualisiert"
echo "***************************************"
apt update -y && apt dist-upgrade -y

apt install curl motion ffmpeg v4l-utils -y
apt install python2 -y
sleep 5
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sleep 5
python2 get-pip.py
sleep 5
apt install libffi-dev libzbar-dev libzbar0 -y
sleep 5
apt install python2-dev libssl-dev libcurl4-openssl-dev libjpeg-dev -y
sleep 5
apt install python-pil -y
sleep 5
usr/local/bin/pip2 install motioneye
sleep 5
mkdir -p /etc/motioneye
cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf
 
mkdir -p /var/lib/motioneye
 
cp /usr/local/share/motioneye/extra/motioneye.systemd-unit-local /etc/systemd/system/motioneye.service
systemctl daemon-reload
systemctl enable motioneye
systemctl start motioneye
 
usr/local/bin/pip2 install motioneye --upgrade

echo "*******************************************************************************************"
echo "motioneye erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP/TEST/"
echo "**************************************************************************"
