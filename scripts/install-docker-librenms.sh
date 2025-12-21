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

echo "librenms installieren"
echo "*******************************"

mkdir /var/librenms/
cd /var/librenms/

tee docker-compose.yml >/dev/null <<EOF
name: librenms

services:
  db:
    image: mariadb:10
    container_name: librenms_db
    command:
      - "mysqld"
      - "--innodb-file-per-table=1"
      - "--lower-case-table-names=0"
      - "--character-set-server=utf8mb4"
      - "--collation-server=utf8mb4_unicode_ci"
    volumes:
      - "./db:/var/lib/mysql"
    environment:
      - "TZ=${TZ}"
      - "MARIADB_RANDOM_ROOT_PASSWORD=yes"
      - "MYSQL_DATABASE=${MYSQL_DATABASE}"
      - "MYSQL_USER=${MYSQL_USER}"
      - "MYSQL_PASSWORD=${MYSQL_PASSWORD}"
    restart: always

  redis:
    image: redis:7.2-alpine
    container_name: librenms_redis
    environment:
      - "TZ=${TZ}"
    restart: always

  msmtpd:
    image: crazymax/msmtpd:latest
    container_name: librenms_msmtpd
    env_file:
      - "./msmtpd.env"
    restart: always

  librenms:
    image: librenms/librenms:latest
    container_name: librenms
    hostname: librenms
    cap_add:
      - NET_ADMIN
      - NET_RAW
    ports:
      - target: 8000
        published: 8000
        protocol: tcp
    depends_on:
      - db
      - redis
      - msmtpd
    volumes:
      - "./librenms:/data"
    env_file:
      - "./librenms.env"
    environment:
      - "TZ=${TZ}"
      - "PUID=${PUID}"
      - "PGID=${PGID}"
      - "DB_HOST=db"
      - "DB_NAME=${MYSQL_DATABASE}"
      - "DB_USER=${MYSQL_USER}"
      - "DB_PASSWORD=${MYSQL_PASSWORD}"
      - "DB_TIMEOUT=60"
    restart: always

  dispatcher:
    image: librenms/librenms:latest
    container_name: librenms_dispatcher
    hostname: librenms-dispatcher
    cap_add:
      - NET_ADMIN
      - NET_RAW
    depends_on:
      - librenms
      - redis
    volumes:
      - "./librenms:/data"
    env_file:
      - "./librenms.env"
    environment:
      - "TZ=${TZ}"
      - "PUID=${PUID}"
      - "PGID=${PGID}"
      - "DB_HOST=db"
      - "DB_NAME=${MYSQL_DATABASE}"
      - "DB_USER=${MYSQL_USER}"
      - "DB_PASSWORD=${MYSQL_PASSWORD}"
      - "DB_TIMEOUT=60"
      - "DISPATCHER_NODE_ID=dispatcher1"
      - "SIDECAR_DISPATCHER=1"
    restart: always

  syslogng:
    image: librenms/librenms:latest
    container_name: librenms_syslogng
    hostname: librenms-syslogng
    cap_add:
      - NET_ADMIN
      - NET_RAW
    depends_on:
      - librenms
      - redis
    ports:
      - target: 514
        published: 514
        protocol: tcp
      - target: 514
        published: 514
        protocol: udp
    volumes:
      - "./librenms:/data"
    env_file:
      - "./librenms.env"
    environment:
      - "TZ=${TZ}"
      - "PUID=${PUID}"
      - "PGID=${PGID}"
      - "DB_HOST=db"
      - "DB_NAME=${MYSQL_DATABASE}"
      - "DB_USER=${MYSQL_USER}"
      - "DB_PASSWORD=${MYSQL_PASSWORD}"
      - "DB_TIMEOUT=60"
      - "SIDECAR_SYSLOGNG=1"
    restart: always

  snmptrapd:
    image: librenms/librenms:latest
    container_name: librenms_snmptrapd
    hostname: librenms-snmptrapd
    cap_add:
      - NET_ADMIN
      - NET_RAW
    depends_on:
      - librenms
      - redis
    ports:
      - target: 162
        published: 162
        protocol: tcp
      - target: 162
        published: 162
        protocol: udp
    volumes:
      - "./librenms:/data"
    env_file:
      - "./librenms.env"
    environment:
      - "TZ=${TZ}"
      - "PUID=${PUID}"
      - "PGID=${PGID}"
      - "DB_HOST=db"
      - "DB_NAME=${MYSQL_DATABASE}"
      - "DB_USER=${MYSQL_USER}"
      - "DB_PASSWORD=${MYSQL_PASSWORD}"
      - "DB_TIMEOUT=60"
      - "SIDECAR_SNMPTRAPD=1"
    restart: always
EOF

tee .env >/dev/null <<EOF
TZ=Europe/Berlin
PUID=1000
PGID=1000

MYSQL_DATABASE=librenms
MYSQL_USER=librenms
MYSQL_PASSWORD=asupersecretpassword
EOF

tee librenms.env >/dev/null <<EOF
MEMORY_LIMIT=256M
MAX_INPUT_VARS=1000
UPLOAD_MAX_SIZE=16M
OPCACHE_MEM_SIZE=128
REAL_IP_FROM=0.0.0.0/32
REAL_IP_HEADER=X-Forwarded-For
LOG_IP_VAR=remote_addr

CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=redis

LIBRENMS_SNMP_COMMUNITY=librenmsdocker

LIBRENMS_WEATHERMAP=false
LIBRENMS_WEATHERMAP_SCHEDULE=*/5 * * * *
EOF

tee msmtpd.env >/dev/null <<EOF
# https://github.com/crazy-max/docker-msmtpd
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_TLS=on
SMTP_STARTTLS=on
SMTP_TLS_CHECKCERT=on
SMTP_AUTH=on
SMTP_USER=foo
SMTP_PASSWORD=bar
SMTP_FROM=foo@gmail.com
EOF

$ docker compose up -d
$ docker compose logs -f





tee /etc/issue >/dev/null <<EOF
\4:8000


EOF

clear

clear

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:8000"
echo "Username: Administrator"
echo "Password: admin"
echo "*************************************************************"
