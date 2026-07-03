#!/usr/bin/env bash
set -euo pipefail

cd /data

if [[ "${EULA^^}" != "TRUE" ]]; then
    echo "ERROR: Minecraft EULA agreement is required."
    echo "Set EULA=TRUE in docker-compose.yml or docker run environment variables."
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

mkdir -p mods config world logs

cat > user_jvm_args.txt <<EOF
-Xms${JVM_XMS}
-Xmx${JVM_XMX}
${JVM_ARGS}
EOF

echo "Starting Minecraft Forge server..."
echo "JVM_XMS=${JVM_XMS}"
echo "JVM_XMX=${JVM_XMX}"

# Modern Forge installers often generate a run.sh.
if [[ -f "./run.sh" ]]; then
    chmod +x ./run.sh
    exec ./run.sh nogui
fi

# Fallback for legacy Forge server compatibility
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

# Final fallback
server_jar="$(
    find . -maxdepth 1 -type f \
        -name '*.jar' \
        ! -name '*installer*.jar' \
        | sort \
        | head -n 1
)"

if [[ -n "${server_jar}" ]]; then
    read -r -a EXTRA_JVM_ARGS <<< "${JVM_ARGS}"
    exec java -Xms"${JVM_XMS}" -Xmx"${JVM_XMX}" "${EXTRA_JVM_ARGS[@]}" -jar "${server_jar}" nogui
fi

echo "ERROR: Could not find an executable Forge server script or JAR."
ls -la
exit 1