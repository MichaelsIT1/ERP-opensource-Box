eu#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert diverse Software.
# Nur fuer Testzwecke. Keine Gewaehrleistung oder Haftung bei Datenverlust.
# Version 0.1

# Variablen
CPW=12345                                                   #Container root-Passwort

# Container Images
DEBIAN10=local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz
DEBIAN11=local:vztmpl/debian-11-standard_11.7-1_amd64.tar.zst 
DEBIAN12=local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
DEBIAN13=local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst
UBUNTU20=local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz
UBUNTU=local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst

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
Es werden wenige/keine Optimierungen, Backups vorgenommen.
****************

Info: Alle Container beginnen ab ID900
1) open3a (Rechnungsprogramm)
5) iTop (CMDB)
7) checkMK-Raw (LAN-Monitoring, debian12)
8) Nextcloud (Zusammenarbeit, debian13)
9) motioneye (Videokamerazentrale, debian12)
-----------------------------------------

DOCKER
50) Portainer (privileged)
51) docspell
52) Invoice Ninja
53) Paperless-ngx (Dokumentenverwaltung mit OCR)
54) ERPNext (ERP-System)


90) debian
99) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in   
    1)  CNAME="open3a"
        COS=$DEBIAN13
        CID=901
        create_container
        pct push $CID scripts/install-open3a.sh /root/install-open3a.sh
        pct exec $CID -- bash -c "sh /root/install-open3a.sh"
        ;;
        
    5)  CNAME="itop"
        COS=$DEBIAN13
        CID=904
        create_container
        pct push $CID scripts/install-itop.sh /root/install-itop.sh
        pct exec $CID -- bash -c "sh /root/install-itop.sh"
        ;;
        
    7)  CNAME="checmk-raw"
        COS=$DEBIAN12
        CID=906
        create_container
        pct push $CID scripts/install-checkmk-raw.sh /root/install-checkmk-raw.sh
        pct exec $CID -- bash -c "sh /root/install-checkmk-raw.sh"
        ;;
        
    8)  CNAME="nextcloud"
        COS=$DEBIAN13
        CID=907
        create_container
        pct push $CID scripts/install-nextcloud.sh /root/install-nextcloud.sh
        pct exec $CID -- bash -c "sh /root/install-nextcloud.sh"
        ;;
        
    9) CNAME="motioneye"
        COS=$DEBIAN12
        CID=908
        create_container
        pct push $CID scripts/install-motioneye.sh /root/install-motioneye.sh
        pct exec $CID -- bash -c "sh /root/install-motioneye.sh"
        ;;
        
 10) CNAME="zammad debian"
        COS=$DEBIAN12
        CID=909
        create_container
        pct push $CID scripts/install-zammad-debian.sh /root/install-zammad-debian.sh
        pct exec $CID -- bash -c "sh /root/install-zammad-debian.sh"
        ;;

11) CNAME="zammad Ubuntu"
        COS=$UBUNTU
        CID=911
        create_container
        pct push $CID scripts/install-zammad-ubuntu.sh /root/install-zammad-ubuntu.sh
        pct exec $CID -- bash -c "sh /root/install-zammad-ubuntu.sh"
        ;;
    
# DOCKER
50) CNAME="Portainer-docker"
        COS=$DEBIAN13
        CID=9999
        create_dockerhost
        pct push $CID scripts/install-docker-portainer.sh /root/install-docker-portainer.sh
        pct exec $CID -- bash -c "sh /root/install-docker-portainer.sh"
        ;;

51) CNAME="docspell-docker"
        #CID=$DOCKERHOST_ID
        COS=$DEBIAN13
        CID=999
        create_dockerhost
        pct push $CID scripts/install-docker-docspell.sh /root/install-docker-docspell.sh
        pct exec $CID -- bash -c "sh /root/install-docker-docspell.sh"
        ;; 

52) CNAME="invoiceninja-docker"
        #CID=$DOCKERHOST_ID
        COS=$DEBIAN13
        CID=999
        create_dockerhost
        pct push $CID scripts/install-docker-invoiceninja.sh /root/install-docker-invoiceninja.sh
        pct exec $CID -- bash -c "sh /root/install-docker-invoiceninja.sh"
        ;; 

53) CNAME="Paperless-ngx-docker"
        COS=$DEBIAN13
        CID=1000
        create_dockerhost
        pct push $CID scripts/install-docker-paperless-ngx.sh /root/install-docker-paperless-ngx.sh
        pct exec $CID -- bash -c "sh /root/install-docker-paperless-ngx.sh"
        ;;

54) CNAME="ERPnext-docker"
        COS=$DEBIAN13
        CID=999
        create_dockerhost
        pct push $CID scripts/install-docker-erpnext.sh /root/install-docker-erpnext.sh
        pct exec $CID -- bash -c "sh /root/install-docker-erpnext.sh"
        ;;
    


90) CNAME="debian"
        COS=$DEBIAN13
        CID=9999
        create_container
        pct push $CID scripts/install-debian.sh /root/install-debian.sh
        pct exec $CID -- bash -c "sh /root/install-debian.sh"
        ;; 


#FEHLERHAFTE SCRIPTE
55) CNAME="NetalertX-docker"
        COS=$DEBIAN13
        CID=1000
        create_dockerhost
        pct push $CID scripts/install-docker-netalertx.sh /root/install-docker-netalertx.sh
        pct exec $CID -- bash -c "sh /root/install-docker-netalertx.sh"
        ;;

56) CNAME="librenms-docker"
        COS=$DEBIAN13
        CID=1001
        create_dockerhost
        pct push $CID scripts/install-docker-librenms.sh /root/install-docker-librenms.sh
        pct exec $CID -- bash -c "sh /root/install-docker-librenms.sh"
        ;;

100)  CNAME="invoice-ninja"
        COS=$DEBIAN13
        CID=900
        create_container
        pct push $CID scripts/install-ninja.sh /root/install-ninja.sh
        pct exec $CID -- bash -c "sh /root/install-ninja.sh"
        ;;

300) CNAME="docker-metafresh"
        COS=$DEBIAN13
        CID=1000
        create_dockerhost
        pct push $CID scripts/install-docker-metafresh.sh /root/install-docker-metafresh.sh
        pct exec $CID -- bash -c "sh /root/install-docker-metafresh.sh"
        ;;

3)  CNAME="dewawi"
        COS=$DEBIAN13
        CID=902
        create_container
        pct push $CID scripts/install-dewawi.sh /root/install-dewawi.sh
        pct exec $CID -- bash -c "sh /root/install-dewawi.sh"
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

# main program
menu
