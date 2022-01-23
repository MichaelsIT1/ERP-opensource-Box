#!/bin/sh
# Dieses Script erstellt einen LXC-Container im Proxmox und installiert xentral opensource
# Nur fuer Testzwecke
# Version 0.1

# Funktionen
menu() {
    clear
    echo "
MAIN MENU
1) xentral opensource installieren
-----------------------------------------
10) lokale Images
0) Exit
Choose an option: "
    read -r ans
    case $ans in
    1)  install_xentral
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

# Installation xentral opensource
install_xentral() {
pct push $CID install-xentral-opensource.sh /root/install-xentral-opensource.sh
pct exec $CID -- bash -c "sh /root/install-xentral-opensource.sh"
}

# main program
menu
