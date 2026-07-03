#!/usr/bin/env bash
set -euo pipefail

if [[ -f ".env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

: "${BACKUP_DIR:=./data/backups}"
: "${BACKUP_KEEP:=10}"

mkdir -p "${BACKUP_DIR}"

if [[ -x "./mcctl.sh" ]]; then
    ./mcctl.sh "say Backup started." || true
    ./mcctl.sh "save-off" || true
    ./mcctl.sh "save-all flush" || ./mcctl.sh "save-all" || true
fi

backup_name="forge-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "${BACKUP_DIR}/${backup_name}" \
    data/world \
    data/mods \
    data/config \
    data/server.properties \
    data/ops.json \
    data/whitelist.json \
    data/banned-players.json \
    data/banned-ips.json 2>/dev/null || true

if [[ -x "./mcctl.sh" ]]; then
    ./mcctl.sh "save-on" || true
    ./mcctl.sh "say Backup completed: ${backup_name}" || true
fi

find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'forge-backup-*.tar.gz' \
    | sort -r \
    | tail -n +$((BACKUP_KEEP + 1)) \
    | xargs -r rm -f

echo "Backup created: ${BACKUP_DIR}/${backup_name}"
