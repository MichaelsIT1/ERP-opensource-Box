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
echo
sleep 3

wget -O - https://get.ispconfig.org | sh -s -- --help

wget -O - https://get.ispconfig.org | sh -s -- --use-php=7.4 --no-dns --no-mailman --no-quota --no-ntp --unattended-upgrades
