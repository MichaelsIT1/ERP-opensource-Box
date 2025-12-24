#!/bin/sh
# Status: Alpha
# Nur fuer Test geeignet. Nicht fuer den produktiven Einsatz.


# System-Varibale
IP=$(ip addr show eth0 | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].*)

apt update && apt dist-upgrade -y
sleep 5

apt install docker.io docker-compose git ca-certificates curl gnupg lsb-release -y
sleep 5
clear

echo "dolibarr installieren"
echo "*******************************"

mkdir /home/dolibarr_mariadb /home/dolibarr_documents /home/dolibarr_custom;

cd /root

tee docker-compose.yml >/dev/null <<EOF
# Edit this file then run 
# docker-compose up -d
# docker-compose logs

services:
    mariadb:
        image: mariadb:latest
        environment:
            MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
            MYSQL_DATABASE: ${MYSQL_DATABASE:-dolidb}
            MYSQL_USER: ${MYSQL_USER:-dolidbuser}
            MYSQL_PASSWORD: ${MYSQL_PASSWORD:-dolidbpass}

        volumes:
            - /home/dolibarr_mariadb:/var/lib/mysql

    web:
        # Choose the version of image to install
        # dolibarr/dolibarr:latest (the latest stable version)
        # dolibarr/dolibarr:develop
        # dolibarr/dolibarr:x.y.z
        image: dolibarr/dolibarr:latest
        environment:
            DOLI_INIT_DEMO: ${DOLI_INIT_DEMO:-0}
            DOLI_DB_HOST: ${DOLI_DB_HOST:-mariadb}
            DOLI_DB_NAME: ${DOLI_DB_NAME:-dolidb}
            DOLI_DB_USER: ${DOLI_DB_USER:-dolidbuser}
            DOLI_DB_PASSWORD: ${DOLI_DB_PASSWORD:-dolidbpass}
            DOLI_URL_ROOT: "${DOLI_URL_ROOT:-http://0.0.0.0}"
            DOLI_ADMIN_LOGIN: "${DOLI_ADMIN_LOGIN:-admin}"
            DOLI_ADMIN_PASSWORD: "${DOLI_ADMIN_PASSWORD:-admin}"
            DOLI_CRON: ${DOLI_CRON:-0}
            DOLI_CRON_KEY: ${DOLI_CRON_KEY:-mycronsecurekey}
            DOLI_COMPANY_NAME: ${DOLI_COMPANY_NAME:-MyBigCompany}
            WWW_USER_ID: ${WWW_USER_ID:-1000}
            WWW_GROUP_ID: ${WWW_GROUP_ID:-1000}

        ports:
            - "80:80"
        links:
            - mariadb
        volumes:
            - /home/dolibarr_documents:/var/www/documents
            - /home/dolibarr_custom:/var/www/html/custom
EOF



docker compose up -d

tee /etc/issue >/dev/null <<EOF
\4

Username: admin
Password: admin

EOF

clear

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP"
echo "Username: admin"
echo "Password: admin"
echo "*************************************************************"
