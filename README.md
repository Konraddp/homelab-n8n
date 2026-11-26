# n8n – Automatisierungen (Homelab)

## Zweck
Selbst betriebenes n8n für drei Strecken: Rechnungs-PDFs aus dem Postfach → Paperless-ngx,
regelbasierte Mailfilterung, morgendliche Tagesagenda.

## Aufbau
- n8n: Workflow-Engine, Editor nur an 127.0.0.1:5678
- n8n-db: PostgreSQL 17 – n8n-interne Daten + Schema `automation`
- Netz: zusätzlich im Docker-Netz `paperless_default`, erreicht Paperless als `http://webserver:8000`

### Deduplizierung
Tabelle `automation.processed_attachments` (angelegt per `db/init.sql` beim ersten Start).
`attachment_sha256` ist UNIQUE: Die Datenbank verhindert Duplikate auch bei parallelen
Ausführungen (kein Check-then-insert). Nötig, weil Paperless v3 Duplikate annimmt.

## Start
    cp .env.example .env          # Secrets setzen
    docker compose up -d          # Paperless-Stack muss vorher laufen (externes Netz)

## Secrets
`N8N_ENCRYPTION_KEY` verschlüsselt alle Credentials in n8n und liegt zusätzlich im
Passwortmanager. Ohne ihn sind Credentials nach einer Wiederherstellung unbrauchbar.

## Stolperstellen
- Aufruf von Paperless aus dem n8n-Container → HTTP 400 (Django `ALLOWED_HOSTS`),
  gelöst im Paperless-Stack mit `PAPERLESS_ALLOWED_HOSTS=localhost,webserver`.
- `db/init.sql` läuft nur bei leerem Volume. Schemaänderungen später per Migration/psql.
- Encryption Key rotiert (war versehentlich geteilt) → Absturz „Deployment key 'signing.hmac'
  cannot be read with this instance encryption key“. n8n 2.x speichert verschlüsselte
  Schlüssel auch in der Datenbank, nicht nur in `~/.n8n`. Ein Wechsel des Keys ist also nur
  vor der Einrichtung trivial (beide Volumes zurücksetzen); danach verliert man die Credentials.
- Encryption Key ein zweites Mal versehentlich geteilt, diesmal nach Anlage von Credentials.
  Rotation: Workflow exportiert, `docker compose down -v`, neuer Key, Owner-Konto und
  Credentials neu angelegt, Gmail-App-Passwort widerrufen und neu erstellt, Workflow importiert.
  Lehre: Secrets nur per `pbcopy` bewegen, nie anzeigen lassen.
- n8n-Export enthält im Block `shared` die E-Mail-Adresse des Owners. `export-workflows.sh`
  entfernt das (und volatile Felder), formatiert lesbar und warnt bei verdächtigen Inhalten.

## Workflows versionieren
    ./export-workflows.sh && git add workflows/ && git commit -m "..."
Import: `docker compose cp workflows/x.json n8n:/tmp/ && docker compose exec n8n n8n import:workflow --input=/tmp/x.json`
