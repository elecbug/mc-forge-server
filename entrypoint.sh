#!/usr/bin/env bash
set -euo pipefail

cd /data

: "${EULA:=FALSE}"
: "${JVM_XMS:=2G}"
: "${JVM_XMX:=6G}"
: "${JVM_ARGS:=}"
: "${ENABLE_RCON:=TRUE}"
: "${RCON_PORT:=25575}"
: "${RCON_PASSWORD:=change-this-rcon-password}"

if [[ "${EULA^^}" != "TRUE" ]]; then
    echo "ERROR: Minecraft EULA agreement is required."
    echo "Set EULA=TRUE in .env, docker-compose.yml, or docker run environment variables."
    exit 1
fi

# On first run, copy the Forge server files installed during build to /data.
# /data is kept as a volume so world, mods, and config persist after container recreation.
if [[ ! -f ".forge-server-initialized" ]]; then
    echo "Initializing Forge server directory..."
    cp -R --no-preserve=mode,ownership,timestamps /opt/minecraft/server-template/. /data/
    touch .forge-server-initialized
fi

echo "eula=true" > eula.txt

mkdir -p mods config world logs backups

touch server.properties

set_prop() {
    local key="$1"
    local value="$2"
    local file="server.properties"
    local tmp

    tmp="$(mktemp)"

    awk -v key="$key" -v value="$value" '
        BEGIN { found = 0 }
        $0 ~ "^" key "=" {
            print key "=" value
            found = 1
            next
        }
        { print }
        END {
            if (found == 0) {
                print key "=" value
            }
        }
    ' "$file" > "$tmp"

    mv "$tmp" "$file"
}

# Basic server settings managed by environment.
set_prop "server-port" "25565"

# RCON settings. Keep RCON unexposed in docker-compose.yml and control it through mcctl.
if [[ "${ENABLE_RCON^^}" == "TRUE" ]]; then
    if [[ -z "${RCON_PASSWORD}" ]]; then
        echo "ERROR: ENABLE_RCON=TRUE but RCON_PASSWORD is empty."
        exit 1
    fi

    if [[ "${RCON_PASSWORD}" == "change-this-rcon-password" ]]; then
        echo "WARNING: RCON_PASSWORD is still the default placeholder. Change it in .env before real use."
    fi

    set_prop "enable-rcon" "true"
    set_prop "rcon.port" "${RCON_PORT}"
    set_prop "rcon.password" "${RCON_PASSWORD}"
else
    set_prop "enable-rcon" "false"
fi

cat > user_jvm_args.txt <<EOF_ARGS
-Xms${JVM_XMS}
-Xmx${JVM_XMX}
${JVM_ARGS}
EOF_ARGS

echo "Starting Minecraft Forge server..."
echo "JVM_XMS=${JVM_XMS}"
echo "JVM_XMX=${JVM_XMX}"
echo "ENABLE_RCON=${ENABLE_RCON}"
echo "RCON_PORT=${RCON_PORT}"

# Modern Forge installers often generate a run.sh.
if [[ -f "./run.sh" ]]; then
    sed -i 's/\r$//' ./run.sh || true
    chmod +x ./run.sh || true
    exec ./run.sh nogui
fi

# Fallback for legacy Forge server compatibility.
forge_jar="$(
    find . -maxdepth 1 -type f \
        \( -name 'forge-*.jar' -o -name '*forge*.jar' \) \
        ! -name '*installer*.jar' \
        | sort \
        | head -n 1
)"

if [[ -n "${forge_jar}" ]]; then
    read -r -a EXTRA_JVM_ARGS <<< "${JVM_ARGS}"
    exec java -Xms"${JVM_XMS}" -Xmx"${JVM_XMX}" "${EXTRA_JVM_ARGS[@]}" -jar "${forge_jar}" nogui
fi

# Final fallback.
server_jar="$(
    find . -maxdepth 1 -type f \
        -name '*.jar' \
        ! -name '*installer*.jar' \
        | sort \
        | head -n 1
)"

echo "Server JAR: ${server_jar}" 

if [[ -n "${server_jar}" ]]; then
    read -r -a EXTRA_JVM_ARGS <<< "${JVM_ARGS}"
    exec java -Xms"${JVM_XMS}" -Xmx"${JVM_XMX}" "${EXTRA_JVM_ARGS[@]}" -jar "${server_jar}" nogui
fi

echo "ERROR: Could not find an executable Forge server script or JAR."
ls -la
exit 1
