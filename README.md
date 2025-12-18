# Lizenz: GPL V3.
# Dies ist ein privates Projekt.
# Nur für Testzwecke. Es erfolgt z.B. kein Backup oder Optimierungen
# auf eigenes Risiko, ohne Gewähr
# für Rückfragen info@edv-spoor.de
# ERP-opensource-Box für x64

Updates:  
Invoice Ninja: Script für docker Installation erstellt. am 18.12.25 auf Funktionalität geprüft
Invoice Ninja: Script für debian 13 angepasst. am 18.12.25 auf Funktionalität geprüft (viele Sprachen fehlen)  
nextcloud: Script für debian 13 angepasst. am 17.12.25 auf Funktionalität geprüft  
checkMK-Raw (Netzwerkmonitoring): am 28.04.25 auf Funktionalität geprüft (debian12)   
Invoice Ninja: am 28.04.25 auf Funktionalität geprüft (debian12)   
Zammad: Script für debian 12 in Arbeit  
open3a: Script für debian 12 angepasst.  
motioneye: Script für debian 12 angepasst.  
checkmk_raw: Script für debian 12 angepasst.  
Invoice Ninja: Script für debian 12 angepasst. am 25.04.25 auf Funktionalität geprüft  
nextcloud: Script für debian 12 angepasst. am 10.12.23 auf Funktionalität geprüft  


HINWEIS: das DEWAWI-Script ist fehlerhaft. Wer möchte kann dies gern fixen. 

Mit dieser Toolbox kann von Proxmox als Host spezielle LXC-Container installiert werden.
Diese Toolbox soll Existensgründer diverser Programme eine einfache Installation bieten.

Folgende Software können installiert werden. Hinweis: Die LXC-Container werden ab ID 900 installiert.

- Invoice Ninja (Rechnungsprogramm) -> https://www.invoiceninja.org oder https://www.invoiceninja.com
- open3a (Rechnungsprogramm) -> https://www.open3a.de
- ISPConfig (Hosting und Mailserver) -> https://www.ispconfig.de/ oder https://www.ispconfig.org/
- iTop (CMDB + Ticketsystem) -> https://www.combodo.com/itop-193
- i-doit (CMDB) -> https://www.i-doit.org oder https://www.i-doit.com/
- checkMK-Raw (Netzwerkmonitoring) -> https://checkmk.com/de
- Nextcloud (Zusammenarbeit) -> https://nextcloud.com/
- motioneye (Kamerazentrale) -> https://github.com/motioneye-project/motioneye
- zammad (Ticketsystem) -> https://zammad.org oder https://zammad.com

---

Benutzung
--

auf dem Proxmox-Host (Server auf dem Proxmox VE läuft)  
git clone https://github.com/MichaelsIT1/ERP-opensource-Box.git  
cd ERP-opensource-Box  
sh 01-start.sh  


vi 01-start.sh

Pfade und ggfs. ID, Passwort u.a. anpassen

Alle Einstellungen werden in der 01-start.sh vorgenommen.

**Ganz oben müssen die Pfade zur den LXC Images angepasst werden.**
---

Rechtliches
--
Die Software ist in der Regel unter einer freien Lizenz.
Die Software bitte nur zur Evalierungzwecken installieren.
Die einzelne Software ist nicht angepasst. Es werden auch keine Datensicherungen vorgenommen.
Als Beispiel Nextcloud. Nextcloud kann mit dem Script installiert werden. Es werden aber keine Optimierungen an PHP z.B. vorgenommen.

Die eizelne Rechte liegen bei den jeweiligen Firmen/Entwickler.
Ich bin nicht der Entwickler der einzelnen Software.

# DETAILS
**Zammad**
Continue with installation? [y/N] -> y wählen
----------------------------------------------------------------------------------------------------------------------------
**ISPConfig TESTVERSION**

Das Installationsskript bereitet den Server für das eigentliche Installationskript vor.

Ich empfehle dieses nur zum Testen.

**Für eine produktive Umgebung würde ich dieses Skript nehmen: https://www.howtoforge.com/ispconfig-autoinstall-debian-ubuntu/**

Webseiten: https://www.ispconfig.org, https://www.ispconfig.de

--------------------------------------------------------------------------------------------------------------------------------
