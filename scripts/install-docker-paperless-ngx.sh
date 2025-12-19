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




tee docker-compose.postgres.yml >/dev/null <<EOF
# Docker Compose file for running paperless from the Docker Hub.
# This file contains everything paperless needs to run.
# Paperless supports amd64, arm and arm64 hardware.
#
# All compose files of paperless configure paperless in the following way:
#
# - Paperless is (re)started on system boot, if it was running before shutdown.
# - Docker volumes for storing data are managed by Docker.
# - Folders for importing and exporting files are created in the same directory
#   as this file and mounted to the correct folders inside the container.
# - Paperless listens on port 8000.
#
# In addition to that, this Docker Compose file adds the following optional
# configurations:
#
# - Instead of SQLite (default), PostgreSQL is used as the database server.
#
# To install and update paperless with this file, do the following:
#
# - Copy this file as 'docker-compose.yml' and the files 'docker-compose.env'
#   and '.env' into a folder.
# - Run 'docker compose pull'.
# - Run 'docker compose up -d'.
#
# For more extensive installation and update instructions, refer to the
# documentation.
services:
  broker:
    image: docker.io/library/redis:8
    restart: unless-stopped
    volumes:
      - redisdata:/data
  db:
    image: docker.io/library/postgres:18
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless
  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - db
      - broker
    ports:
      - "8000:8000"
    volumes:
      - data:/usr/src/paperless/data
      - media:/usr/src/paperless/media
      - ./export:/usr/src/paperless/export
      - ./consume:/usr/src/paperless/consume
    env_file: docker-compose.env
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBHOST: db
volumes:
  data:
  media:
  pgdata:
  redisdata:
EOF



tee .env >/dev/null <<EOF
COMPOSE_PROJECT_NAME=paperless
EOF


docker compose pull
sleep 5

docker compose up -d


# Text vor der Anmeldung
tee /etc/issue >/dev/null <<EOF
http://\4:5432

EOF

#CLEAR

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:5432/"
echo "*************************************************************"
