#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert xentral opensource
# Nur fuer Testzwecke
# Version 0.1

# Variable
# Container-ID
CID=999

clear

# Container wird erzeugt
pct create $CID local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz \
        -hostname xentral-test \
        -rootfs local-zfs:8 \
        -cores 2 \
        -memory 4096 \
        -net0 name=eth0,bridge=vmbr0,ip=dhcp \
        -unprivileged 1 \
        -password 12345 \
        -features nesting=1

pct start $CID
sleep 10

pct exec $CID -- bash -c "apt install git -y && git clone https://github.com/MichaelsIT1/ERP-opensource-Box.git"

lxc-attach -n$CID bash /root/ERP-opensource-Box/install-xentral-opensource.sh
