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

echo "NetAlertX installieren"
echo "*******************************"

cd /root
tee docker-compose.yml >/dev/null <<EOF
services:
  netalertx:
  #use an environmental variable to set host networking mode if needed
    container_name: netalertx                       # The name when you docker contiainer ls
    image: ghcr.io/jokob-sk/netalertx:latest
    #network_mode: ${NETALERTX_NETWORK_MODE:-host}   # Use host networking for ARP scanning and other services
    network_mode: host
    read_only: true                                 # Make the container filesystem read-only
    cap_drop:                                       # Drop all capabilities for enhanced security
      - ALL
    cap_add:                                        # Add only the necessary capabilities
      - NET_ADMIN                                   # Required for ARP scanning
      - NET_RAW                                     # Required for raw socket operations
      - NET_BIND_SERVICE                            # Required to bind to privileged ports (nbtscan)

    volumes:
      - type: volume                                # Persistent Docker-managed named volume for config + database
        source: netalertx_data
        target: /data                               # `/data/config` and `/data/db` live inside this mount
        read_only: false

    # Example custom local folder called /home/user/netalertx_data
    # - type: bind
    #   source: /home/user/netalertx_data
    #   target: /data
    #   read_only: false
    # ... or use the alternative format
    # - /home/user/netalertx_data:/data:rw

      - type: bind                                  # Bind mount for timezone consistency
        source: /etc/localtime
        target: /etc/localtime
        read_only: true

      # Mount your DHCP server file into NetAlertX for a plugin to access
      # - path/on/host/to/dhcp.file:/resources/dhcp.file

    # tmpfs mount consolidates writable state for a read-only container and improves performance
    # uid=20211 and gid=20211 is the netalertx user inside the container
    # mode=1700 grants rwx------ permissions to the netalertx user only
    tmpfs:
      # Comment out to retain logs between container restarts - this has a server performance impact.
      - "/tmp:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev,async,noatime,nodiratime"

      # Retain logs - comment out tmpfs /tmp if you want to retain logs between container restarts
      # Please note if you remove the /tmp mount, you must create and maintain sub-folder mounts.
      # - /path/on/host/log:/tmp/log
      # - "/tmp/api:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev,async,noatime,nodiratime"
      # - "/tmp/nginx:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev,async,noatime,nodiratime"
      # - "/tmp/run:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev,async,noatime,nodiratime"

    environment:
      LISTEN_ADDR: ${LISTEN_ADDR:-0.0.0.0}                   # Listen for connections on all interfaces
      PORT: ${PORT:-20211}                                   # Application port
      GRAPHQL_PORT: ${GRAPHQL_PORT:-20212}                   # GraphQL API port (passed into APP_CONF_OVERRIDE at runtime)
  #    NETALERTX_DEBUG: ${NETALERTX_DEBUG:-0}                 # 0=kill all services and restart if any dies. 1 keeps running dead services.

    # Resource limits to prevent resource exhaustion
    mem_limit: 2048m            # Maximum memory usage
    mem_reservation: 1024m      # Soft memory limit
    cpu_shares: 512             # Relative CPU weight for CPU contention scenarios
    pids_limit: 512             # Limit the number of processes/threads to prevent fork bombs
    logging:
      driver: "json-file"       # Use JSON file logging driver
      options:
        max-size: "10m"         # Rotate log files after they reach 10MB
        max-file: "3"           # Keep a maximum of 3 log files

    # Always restart the container unless explicitly stopped
    restart: unless-stopped

volumes:                        # Persistent volume for configuration and database storage
  netalertx_data:
EOF



docker compose up --force-recreate







tee /etc/issue >/dev/null <<EOF
\4:8080


EOF

clear

echo "weiter gehts mit dem Browser. Gehen Sie auf http://$IP:8080"
echo "Username: Administrator"
echo "Password: admin"
echo "*************************************************************"
