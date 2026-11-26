#!/usr/bin/env bash
# Exportiert alle n8n-Workflows ins Repo: lesbar formatiert, ohne Besitzerdaten und
# ohne Felder, die sich bei jedem Speichern ändern.
set -euo pipefail
cd "$(dirname "$0")"

docker compose exec -T n8n n8n export:workflow --all --separate --output=/tmp/export/ >/dev/null
rm -rf workflows && mkdir -p workflows
docker compose cp n8n:/tmp/export/. ./workflows/ >/dev/null
docker compose exec -T n8n rm -rf /tmp/export

for f in workflows/*.json; do
  name=$(jq -r '.name | ascii_downcase | gsub("[^a-z0-9]+"; "-")' "$f")
  jq 'del(.shared, .createdAt, .updatedAt, .versionId, .activeVersionId,
          .versionCounter, .triggerCount, .meta, .versionMetadata, .pinData)' "$f" > "workflows/$name.json.tmp"
  rm "$f" && mv "workflows/$name.json.tmp" "workflows/$name.json"
done

if grep -rqiE '@gmail|"password"|"token"' workflows/; then
  echo "WARNUNG: möglicherweise sensible Daten in workflows/ – vor dem Commit prüfen!" >&2
  exit 1
fi
ls -1 workflows/
