# Lizenz: GPL V3.
# Dies ist ein privates Projekt.
# Nur für Testzwecke. Es erfolgt z.B. kein Backup oder Optimierungen
# auf eigenes Risiko, ohne Gewähr
# für Rückfragen info@edv-spoor.de
# ERP-opensource-Box

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
- docker Portainer (Container Management)-> https://www.portainer.io

--

Benutzung
--
Alle Einstellungen werden in der 01_start.sh vorgenommen.

**Ganz oben müssen die Pfade zur den LXC Images angepasst werden.**

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
