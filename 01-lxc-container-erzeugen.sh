# Dieses Script erstellt einen LXC-Container im Proxmox und installiert xentral opensource
# Nur fuer Testzwecke
# Version 0.1

!/bin/sh
clear

# Container wird erzeugt
pct create 999 local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz \
        -hostname xentral-test \
        -rootfs local-zfs:8 \
        -cores 2 \
        -memory 4096 \
        -net0 name=eth0,bridge=vmbr0,ip=dhcp \
        -unprivileged 1 \
        -password 12345 \
        -features nesting=1

pct start 999
sleep 10

pct exec 999 -- bash -c "wget https://github.com/MichaelsIT1/ERP-opensource-Box/blob/main/install-xentral-opensource.sh && chmod +x install-xentral-opensource.sh"

lxc-attach -n999 bash /root/ERP-opensource-Box/install-xentral-opensource.sh
