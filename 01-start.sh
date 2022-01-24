#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert xentral opensource
# Nur fuer Testzwecke
# Version 0.1

# Variablen
CID=999                                                     #Container-ID
COS=local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz     #Container Images
CPW=12345                                                   #Container root-Passwort

# Container Images
COS_DEBIAN=local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz     
COS_UBUNTU=local:vztmpl/ubuntu-21.10-standard_21.10-1_amd64.tar.zst 

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
1) xentral opensource installieren
2) metafresh installieren
-----------------------------------------
10) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in
    1)  COS=$COS_DEBIAN
        CNAME=xentral-test 
        create_container
        install_xentral
        ;;
        
    2)  COS=$COS_UBUNTU
        CNAME=metafresh-test
        create_container
        install_metafresh
        ;;
        
    10) pveam list local
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

# Container erzeugen
create_container() {
clear
pct create $CID $COS \
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

# Installation xentral opensource
install_xentral() {
pct push $CID install-xentral-opensource.sh /root/install-xentral-opensource.sh
pct exec $CID -- bash -c "sh /root/install-xentral-opensource.sh"
}

install_metafresh() {
pct push $CID install-metafresh.sh /root/install-metafresh.sh
pct exec $CID -- bash -c "sh /root/install-metafresh.sh"
}

# main program
menu
