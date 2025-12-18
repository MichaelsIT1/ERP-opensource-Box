eu#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert diverse Software.
# Nur fuer Testzwecke. Keine Gewaehrleistung oder Haftung bei Datenverlust.
# Version 0.1

# Variablen

#Container root-Passwort
CPW=12345   

# DOCKERHOST-ID
DOCKERHOST_ID=949

# Container Images
DEBIAN13=local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst

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
DOCKER
50) Dockerhost erzeugen (privileged, mit Portainer debian)
55) docker-docspell
60) Invoice Ninja

99) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in
   
50) CNAME="dockerhost-Portainer"
        COS=$DEBIAN13
        CID=$DOCKERHOST_ID
        create_dockerhost
        install_portainer
        ;;

55) CNAME="docspell (Docker)"
        CID=$DOCKERHOST_ID
        install_docspell
        ;; 

60) CNAME="invoiceninja (Docker)"
        CID=$DOCKERHOST_ID
        install_docker_invoiceninja
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

# DOCKER
install_portainer() {
pct push $CID scripts/install-portainer.sh /root/install-portainer.sh
pct exec $CID -- bash -c "sh /root/install-portainer.sh"
}

install_docspell() {
pct push $CID scripts/install-docspell.sh /root/install-docspell.sh
pct exec $CID -- bash -c "sh /root/install-docspell.sh"
}

install_docker_invoiceninja() {
pct push $CID scripts/install-docker-invoiceninja.sh /root/install-docker-invoiceninja.sh
pct exec $CID -- bash -c "sh /root/install-docker-invoiceninja.sh"
}
# main program
menu
