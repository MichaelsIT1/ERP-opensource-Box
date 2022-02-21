#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert diverse Software.
# Nur fuer Testzwecke. Keine Gewaehrleistung oder Haftung bei Datenverlust.
# Version 0.1

# Variablen
CID=999                                                     #Container-ID
CPW=12345                                                   #Container root-Passwort

# Container Images
DEBIAN10=local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz
DEBIAN11=local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz     
UBUNTU=local:vztmpl/ubuntu-21.10-standard_21.10-1_amd64.tar.zst 

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
1) xentral opensource installieren
2) open3a installieren
3) metafresh installieren - Docker
4) ISPConfig installieren
5) iTop installieren
6) i-doit installieren
-----------------------------------------
10) docker Portainer installieren
11) Debian 11 Container
19) Container 999 löschen
20) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in
    1)  CNAME="xentral-test"
        COS=$DEBIAN11
        create_container
        install_xentral
        ;;
        
    2)  CNAME="open3a-test"
        COS=$DEBIAN11
        create_container
        install_open3a
        ;;
        
    3)  CNAME="metafresh-test"
        COS=$UBUNTU # only Ubuntu
        create_container
        install_metafresh
        ;;        
        
    4)  CNAME="ispconfig-test"
        COS=$DEBIAN11
        create_container
        install_ispconfig
        ;;
        
    5)  CNAME="itop-test"
        COS=$DEBIAN11
        create_container
        install_itop
        ;;
        
    6)  CNAME="i-doit-test"
        COS=$DEBIAN11
        create_container
        install_idoit
        ;;
        
        
    10) CNAME="portainer-test"
        COS=$UBUNTU
        create_container
        install_portainer
        ;;
        
    11) CNAME="Debian11-test"
        COS=$DEBIAN11
        create_container
        install_debian
        ;;

    19) pct stop 999 && pct destroy 999
        ;;
    
    20) pveam list local
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
        -password $CPW \
        -rootfs local-zfs:32 \
        -cores 2 \
        -memory 4096 \
        -net0 name=eth0,bridge=vmbr0,ip=dhcp \
        -unprivileged 1 \
        -features nesting=1,keyctl=1

pct start $CID
sleep 10
}

# Installation xentral opensource
install_xentral() {
pct push $CID scripts/install-xentral-opensource.sh /root/install-xentral-opensource.sh
pct exec $CID -- bash -c "sh /root/install-xentral-opensource.sh"
}

install_open3a() {
pct push $CID scripts/install-open3a.sh /root/install-open3a.sh
pct exec $CID -- bash -c "sh /root/install-open3a.sh"
}

install_ispconfig() {
pct push $CID scripts/install-ispconfig.sh /root/install-ispconfig.sh
pct exec $CID -- bash -c "sh /root/install-ispconfig.sh"
}

install_debian() {
pct push $CID scripts/install-debian.sh /root/install-debian.sh
pct exec $CID -- bash -c "sh /root/install-debian.sh"
}

install_metafresh() {
pct push $CID scripts/install-metafresh.sh /root/install-metafresh.sh
pct exec $CID -- bash -c "sh /root/install-metafresh.sh"
}

install_portainer() {
pct push $CID scripts/install-portainer.sh /root/install-portainer.sh
pct exec $CID -- bash -c "sh /root/install-portainer.sh"
}

install_itop() {
pct push $CID scripts/install-itop.sh /root/install-itop.sh
pct exec $CID -- bash -c "sh /root/install-itop.sh"
}

install_idoit() {
pct push $CID scripts/install-idoit /root/install-idoit.sh
pct exec $CID -- bash -c "sh /root/install-idoit.sh"
}

# main program
menu
