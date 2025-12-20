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




tee /root/docker-compose.yml >/dev/null <<EOF
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

sleep 5

tee /root/docker-compose.env >/dev/null <<EOF
###############################################################################
# Paperless-ngx settings                                                      #
###############################################################################

# See http://docs.paperless-ngx.com/configuration/ for all available options.

# The UID and GID of the user used to run paperless in the container. Set this
# to your UID and GID on the host so that you have write access to the
# consumption directory.
#USERMAP_UID=1000
#USERMAP_GID=1000

# See the documentation linked above for all options. A few commonly adjusted settings
# are provided below.

# This is required if you will be exposing Paperless-ngx on a public domain
# (if doing so please consider security measures such as reverse proxy)
#PAPERLESS_URL=https://paperless.example.com

# Adjust this key if you plan to make paperless available publicly. It should
# be a very long sequence of random characters. You don't need to remember it.
#PAPERLESS_SECRET_KEY=change-me

# Use this variable to set a timezone for the Paperless Docker containers. Defaults to UTC.
#PAPERLESS_TIME_ZONE=America/Los_Angeles

# The default language to use for OCR. Set this to the language most of your
# documents are written in.
#PAPERLESS_OCR_LANGUAGE=eng

# Additional languages to install for text recognition, separated by a whitespace.
# Note that this is different from PAPERLESS_OCR_LANGUAGE (default=eng), which defines
# the language used for OCR.
# The container installs English, German, Italian, Spanish and French by default.
# See https://packages.debian.org/search?keywords=tesseract-ocr-&searchon=names
# for available languages.
#PAPERLESS_OCR_LANGUAGES=tur ces
EOF

sleep 5

tee /root/.env >/dev/null <<EOF
COMPOSE_PROJECT_NAME=paperless
EOF

sleep 5

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
