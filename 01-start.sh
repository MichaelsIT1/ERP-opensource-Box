#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert diverse Software.
# Nur fuer Testzwecke. Keine Gewaehrleistung oder Haftung bei Datenverlust.
# Version 0.1

# Variablen
CPW=12345                                                   #Container root-Passwort

# Container Images
DEBIAN10=local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz
DEBIAN11=local:vztmpl/debian-11-standard_11.7-1_amd64.tar.zst 
DEBIAN12=local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
UBUNTU20=local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz
UBUNTU=local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# DOCKERHOST-ID
DOCKERHOST_ID=949

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
***************
Michas Toölbox

WICHTIG: 
Für Datenverlust oder sonstiges übernehem ich keine Haftung.
Bitte benutzen Sie das Script wenn Sie fachkundig sind.
Dieses Script hilft Ihnen Software zu installieren.
Es werden keine Optimierungen, Backups vorgenommen.
****************

Info: Alle Container beginnen ab ID900
1) Invoice Ninja (Rechnungsprogramm, debian12)
2) open3a (Rechnungsprogramm, debian12)
3) DEWAWI (Warenwirtschaft) FEHLER
4) ISPConfig (Webseitenhosting/Mailserver) 
5) iTop (CMDB)
6) i-doit (CMDB)
7) checkMK-Raw (LAN-Monitoring, debian12)
8) Nextcloud (Zusammenarbeit, debian12)
9) motioneye (Videokamerazentrale, debian12)
10) Zammad (Ticketsystem, debian12 FEHLER)
11) Zammad (Ticketsystem, Ubuntu22.04)
-----------------------------------------
DOCKER
50) Dockerhost (privileged, mit Portainer debian)
55) docker-docspell

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
        COS=$DEBIAN12
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
        COS=$DEBIAN12
        CID=909
        create_container
        install_zammad_debian
        ;;

11) CNAME="zammad"
        COS=$UBUNTU
        CID=911
        create_container
        install_zammad_ubuntu
        ;;
    
# DOCKER
50) CNAME="dockerhost-Portainer"
        COS=$DEBIAN12
        CID=$DOCKERHOST_ID
        create_dockerhost
        install_portainer
        ;;

55) CNAME="docker-docspell"
        CID=$DOCKERHOST_ID
        install_docspell
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
        -features nesting=1

pct start $CID
sleep 10
}

# DOCKERHOST erzeugen
create_dockerhost() {
clear
pct create $CID $COS \
        -hostname $CNAME \
        -password $CPW \
        -rootfs local-zfs:32 \
        -cores 2 \
        -memory 4096 \
        -net0 name=eth0,bridge=vmbr0,ip=dhcp \
        -unprivileged 0 \
        -features nesting=1

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

install_zammad_debian() {
pct push $CID scripts/install-zammad-debian.sh /root/install-zammad-debian.sh
pct exec $CID -- bash -c "sh /root/install-zammad-debian.sh"
}

install_zammad_ubuntu() {
pct push $CID scripts/install-zammad-ubuntu.sh /root/install-zammad-ubuntu.sh
pct exec $CID -- bash -c "sh /root/install-zammad-ubuntu.sh"
}

# DOCKER
install_portainer() {
pct push $CID scripts/install-portainer.sh /root/install-portainer.sh
pct exec $CID -- bash -c "sh /root/install-portainer.sh"
}

install_docspell() {
pct push $CID scripts/install-docspell.sh /root/install-docspell.sh
pct exec $CID -- bash -c "sh /root/install-docspell.sh"
}

# main program
menu
