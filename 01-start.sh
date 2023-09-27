#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert diverse Software.
# Nur fuer Testzwecke. Keine Gewaehrleistung oder Haftung bei Datenverlust.
# Version 0.1

# Variablen
CPW=12345                                                   #Container root-Passwort

# Container Images
DEBIAN10=local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz
DEBIAN11=local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz
DEBIAN12=local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst
UBUNTU=local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
1) Invoice Ninja (Rechnungsprogramm)
2) open3a (Rechnungsprogramm)
3) DEWAWI (Warenwirtschaft) FEHLER
4) ISPConfig (Webseitenhosting/Mailserver) 
5) iTop (CMDB)
6) i-doit (CMDB)
7) checkMK-Raw (LAN-Monitoring)
8) Nextcloud (Zusammenarbeit)
9) motioneye (Videokamerazentrale)
10) Zammad (Ticketsystem)
11) docspell (Dokumentenverwaltung mit OCR)
----------------------------------------
DOCKER Software (bitte setzen: -unprivileged 0)
20) Portainer
21) metafresh (ERP)

-----------------------------------------
50) Debian 12 Container
99) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in
    1)  CNAME="invoice-ninja"
        COS=$DEBIAN12
        CID=900
        create_container
        install_ninja
        ;;
        
    2)  CNAME="open3a"
        COS=$DEBIAN11
        CID=901
        create_container
        install_open3a
        ;;
        
    3)  CNAME="dewawi"
        COS=$DEBIAN12
        CID=902
        create_container
        install_dewawi
        ;;   
        
    4)  CNAME="ispconfig-test"
        COS=$DEBIAN11
        CID=903
        create_container
        install_ispconfig
        ;;
        
    5)  CNAME="itop"
        COS=$DEBIAN11
        CID=904
        create_container
        install_itop
        ;;
        
    6)  CNAME="i-doit"
        COS=$DEBIAN11
        CID=905
        create_container
        install_idoit
        ;;
        
    7)  CNAME="checmk-raw"
        COS=$DEBIAN12
        CID=906
        create_container
        install_checkmk
        ;;
        
    8)  CNAME="nextcloud"
        COS=$DEBIAN12
        CID=907
        create_container
        install_nextcloud
        ;;
        
    9) CNAME="motioneye"
        COS=$DEBIAN12
        CID=908
        create_container
        install_motioneye
        ;;
        
 10) CNAME="zammad"
        COS=$UBUNTU
        CID=909
        create_container
        install_zammad
        ;;

11)  CNAME="docspell"
        COS=$DEBIAN11
        CID=910
        create_container
        install_docspell
        ;;   

   
     20) CNAME="docker-portainer"
        COS=$UBUNTU
        CID=919
        create_container
        install_portainer
        ;;
        
    21)  CNAME="metafresh-docker-test"
        COS=$UBUNTU # only Ubuntu
        CID=920
        create_container
        install_metafresh
        ;;
    
    
    50) CNAME="debian12"
        COS=$DEBIAN12
        CID=949
        create_container
        install_debian
        ;;
        
     

    1001)  CNAME="xentral-test"
        COS=$DEBIAN11
        CID=1001
        create_container
        install_xentral
        ;;

    
    99) pveam list local
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
        -features nesting=0,keyctl=0

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

install_dewawi() {
pct push $CID scripts/install-dewawi.sh /root/install-dewawi.sh
pct exec $CID -- bash -c "sh /root/install-dewawi.sh"
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
pct push $CID scripts/install-idoit.sh /root/install-idoit.sh
pct exec $CID -- bash -c "sh /root/install-idoit.sh"
}

install_checkmk() {
pct push $CID scripts/install-checkmk-raw.sh /root/install-checkmk-raw.sh
pct exec $CID -- bash -c "sh /root/install-checkmk-raw.sh"
}

install_nextcloud() {
pct push $CID scripts/install-nextcloud.sh /root/install-nextcloud.sh
pct exec $CID -- bash -c "sh /root/install-nextcloud.sh"
}

install_motioneye() {
pct push $CID scripts/install-motioneye.sh /root/install-motioneye.sh
pct exec $CID -- bash -c "sh /root/install-motioneye.sh"
}

install_ninja() {
pct push $CID scripts/install-ninja.sh /root/install-ninja.sh
pct exec $CID -- bash -c "sh /root/install-ninja.sh"
}

install_docspell() {
pct push $CID scripts/install-docspell.sh /root/install-docspell.sh
pct exec $CID -- bash -c "sh /root/install-docspell.sh"
}

install_zammad() {
pct push $CID scripts/install-zammad.sh /root/install-zammad.sh
pct exec $CID -- bash -c "sh /root/install-zammad.sh"
}



# main program
menu
