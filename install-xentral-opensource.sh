# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.
# getestet auf Debian 11 im LXC Container
#!/bin/sh
clear
echo "xentral opensource installieren"
echo "*******************************"
echo
echo "Zeitzone auf Europe/Berlin gesetzt"
echo "**********************************"
timedatectl set-timezone Europe/Berlin 
echo
echo "Betriebssystem debian wird aktualisiert"
echo "***************************************"
apt update > /dev/null 2>&1 && apt dist-upgrade -y > /dev/null 2>&1
echo
echo "Webserver Apache, MariaDB und PHP wird installiert"
echo "**************************************************"
apt install apache2 mariadb-server php php-mbstring php-soap php-imap php-xml php-zip php-gd php-cli php-mysql php-curl unzip zip -y > /dev/null 2>&1
echo
echo "xentral opensource herunterladen"
echo "********************************"
wget https://github.com/xentral-erp-software-gmbh/downloads/raw/master/installer.zip > /dev/null 2>&1
echo
echo "Installer.zip wird entpackt und nach var/www/html verschoben"
echo "***********************************************************"
unzip installer.zip > /dev/null 2>&1
mv installer.php /var/www/html/
echo
echo "Zugriffsrechte werden gesetzt"
echo "*****************************"
chown -R www-data:www-data /var/www/html/
echo

if ! mysql -u root -e 'use xentral';
then
        echo "Maria-DB wird konfiguiert und Datenbank angelegt"
        echo "*************************"
        mariadb-secure-installation
        mysql -u root <<EOF
        CREATE DATABASE xentral;
        CREATE USER 'xentral'@'localhost' IDENTIFIED BY 'xentral';
        GRANT ALL PRIVILEGES ON xentral . * TO 'xentral'@'localhost';
        FLUSH PRIVILEGES;
EOF
else
        echo "Datenbank xentral vorhanden"
        echo "****************************"
fi

echo "Cronjob wird erzeugt"
echo "********************"
crontab -u www-data -l > cron_bkp
echo "* * * * * /usr/bin/php /var/www/html/cronjobs/starter2.php > /dev/null 2>&1" >> cron_bkp
crontab -u www-data cron_bkp
rm cron_bkp
echo
echo "xentral openSource erfolgreich installiert. Bitte ueber das Web die Konfiguration vornehmen"
echo "*******************************************************************************************"
