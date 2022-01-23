#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert xentral opensource
# Nur fuer Testzwecke
# Version 0.1

# Variablen
CID=999              #Container-ID
CNAME=xentral-test   #Containername
CPW=12345            #Container root-Passwort

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
1) xentral opensource installieren
0) Exit
Choose an option:  "
    read -r ans
    case $ans in
    1) install_xentral
        ;;
    0)
        echo "Bye bye."
        exit 0
        ;;
    *)
        echo "Wrong option."
        exit 1
        ;;
    esac
}

create_container() {
clear
# Container wird erzeugt
pct create $CID local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz \
        -hostname $CNAME \
        -rootfs local-zfs:8 \
        -cores 2 \
        -memory 4096 \
        -net0 name=eth0,bridge=vmbr0,ip=dhcp \
        -unprivileged 1 \
        -password $CPW \
        -features nesting=1

pct start $CID
sleep 10
}

install_xentral() {
# Installation xentral opensource
pct push $CID install-xentral-opensource.sh /root/install-xentral-opensource.sh
pct exec $CID -- bash -c "sh /root/install-xentral-opensource.sh"
}

# main program
menu
