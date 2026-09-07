#!/usr/bin/env bash
set -e

# Configurazione
OLD_HOST="c.ferdi.cc"
OLD_USER="deploy"
OLD_APP_DIR="/home/deploy/apps/concorsi-locali/current"
OLD_STORAGE_DIR="/home/deploy/apps/concorsi-locali/shared/storage"
TOOL_NAME="statistiche-wlm"
DUMP_FILE="concorsi_data_$(date +%Y%m%d_%H%M%S).json.gz"

echo "=== 1. Esportazione dati dal vecchio server (${OLD_HOST}) ==="
ssh "${OLD_USER}@${OLD_HOST}" "cd ${OLD_APP_DIR} && RAILS_ENV=production bundle exec rake 'db:export_data[/tmp/${DUMP_FILE}]'"

echo "=== 2. Download del dump in locale ==="
scp "${OLD_USER}@${OLD_HOST}:/tmp/${DUMP_FILE}" "./${DUMP_FILE}"
ssh "${OLD_USER}@${OLD_HOST}" "rm -f /tmp/${DUMP_FILE}"

echo "=== 3. Upload del dump su Toolforge Bastion ==="
scp "./${DUMP_FILE}" "login.toolforge.org:/data/project/${TOOL_NAME}/${DUMP_FILE}"

echo "=== 4. (Opzionale) Sincronizzazione file ActiveStorage (loghi concorsi) ==="
echo "Per copiare i loghi caricati dal vecchio server a Toolforge, esegui:"
echo "rsync -avz -e ssh ${OLD_USER}@${OLD_HOST}:${OLD_STORAGE_DIR}/ login.toolforge.org:/data/project/${TOOL_NAME}/storage/"

echo ""
echo "=== 5. Istruzioni per importare i dati su Toolforge ==="
echo "Collegati su Toolforge bastion ed esegui:"
echo "  ssh login.toolforge.org"
echo "  become ${TOOL_NAME}"
echo "  toolforge jobs run import-data-job \\"
echo "    --image tool-${TOOL_NAME}/tool-${TOOL_NAME}:latest \\"
echo "    --command \"bundle exec rake 'db:import_data[/data/project/${TOOL_NAME}/${DUMP_FILE}]'\" \\"
echo "    --mount all \\"
echo "    --wait"
echo ""
echo "  toolforge jobs logs import-data-job"
echo "  toolforge jobs delete import-data-job"
echo "  rm -f /data/project/${TOOL_NAME}/${DUMP_FILE}"
