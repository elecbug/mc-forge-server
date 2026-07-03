#!/usr/bin/env bash
set -euo pipefail

if [[ -f ".env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

: "${CONTAINER_NAME:=mc-forge}"
: "${RCON_PORT:=25575}"
: "${RCON_PASSWORD:=change-this-rcon-password}"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 \"minecraft command\""
    echo "Examples:"
    echo "  $0 \"op Steve\""
    echo "  $0 \"whitelist add Steve\""
    echo "  $0 \"say Server restarts in 5 minutes\""
    echo "  $0 \"save-all\""
    exit 1
fi

if ! docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Container '${CONTAINER_NAME}' does not exist or is not accessible."
    exit 1
fi

docker run --rm -i \
    --network "container:${CONTAINER_NAME}" \
    itzg/rcon-cli \
    --host 127.0.0.1 \
    --port "${RCON_PORT}" \
    --password "${RCON_PASSWORD}" \
    "$*"
