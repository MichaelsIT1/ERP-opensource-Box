# Lizenz: GPL V3.
# Dies ist ein privates Projekt.
# Nur für Testzwecke. Es erfolgt z.B. kein Backup oder Optimierungen
# auf eigenes Risiko, ohne Gewähr
# ERP-opensource-Box

Mit dieser Toolbox kann von Proxmox als Host spezielle LXC-Container installiert werden.
Diese Toolbox soll Existensgründer diverser Programme eine einfache Installation bieten.

Folgende Software können installiert werden. Hinweis: Die LXC-Container werden ab ID 900 installiert.

1) Invoice Ninja (Buchhaltung für kleine Firmen) -> https://www.invoiceninja.org
2) open3a (Rechnungsprogramm) -> https://www.open3a.de
4) ISPConfig (Hosting und Mailserver) -> https://www.ispconfig.de/ oder https://www.ispconfig.org/
5) iTop (CMDB + Ticketsystem)
6) i-doit (CMDB)
7) checkMK-Raw (Netzwerkmonitoring)
8) Nextcloud (Zusammenarbeit)
9) motioneye (Kamerazentrale)
-----------------------------------------
10) docker Portainer installieren
11) Debian 11 Container

Die Software ist in der Regel unter einer freien Lizenz.
Die Software bitte nur zur Evalierungzwecken installieren.
Die einzelne Software ist nicht angepasst. Es werden auch keine Datensicherungen vorgenommen.
Als Beispiel Nextcloud. Nextcloud kann mit dem Script installiert werden. Es werden aber keine Optimierungen an PHP z.B. vorgenommen.

Die eizelne Rechte liegen bei den jeweiligen Firmen/Entwickler.
Ich bin nicht der Entwickler der einzelnen Software.

# DETAILS

**open3a Rechnungsprogramm**

Das Installationsskript basiert weitgehend auf diese Anleitung:
https://www.open3a.de/page-Installation/WebserverSetup

Webseite: https://www.open3a.de

----------------------------------------------------------------------------------------------------------------------------
**ISPConfig TESTVERSION**

Das Installationsskript bereitet den Server für das eigentliche Installationskript vor.
https://www.howtoforge.com/perfect-server-debian-10-buster-apache-bind-dovecot-ispconfig-3-1/

Ich empfehle dieses nur zum Testen.

**Für eine produktive Umgebung würde ich dieses Skript nehmen: https://www.howtoforge.com/ispconfig-autoinstall-debian-ubuntu/**

Webseiten: https://www.ispconfig.org, https://www.ispconfig.de

--------------------------------------------------------------------------------------------------------------------------------
**iTop CMDB + Ticketsystem**

iTop ist ein CMDB und Ticketsystem.

Webseite: https://www.combodo.com

--------------------------------------------------------------------------------------------------------------------------------
**i-doit CMDB**

i-doit ist ein CMDB.

Das Installationsskript basiert auf diese Anleitung:
https://kb.i-doit.com/pages/viewpage.action?pageId=10223831

Webseite: https://www.i-doit.org
