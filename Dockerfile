# syntax=docker/dockerfile:1

# Match this to your Minecraft/Forge version.
# - MC 1.18 ~ 1.20.4: eclipse-temurin:17-jre-jammy
# - MC 1.20.5+ / 1.21+: eclipse-temurin:21-jre-jammy
ARG JAVA_IMAGE=eclipse-temurin:17-jre-jammy

FROM ${JAVA_IMAGE}

ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} minecraft \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash minecraft \
    && mkdir -p /opt/minecraft/server-template /data /tmp/forge-installer \
    && chown -R minecraft:minecraft /opt/minecraft /data /tmp/forge-installer

COPY --chown=minecraft:minecraft jar/*.jar /tmp/forge-installer/
COPY --chown=minecraft:minecraft entrypoint.sh /usr/local/bin/entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod 0755 /usr/local/bin/entrypoint.sh

USER minecraft
WORKDIR /tmp/forge-installer

RUN set -eux; \
    installer_count="$(find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' | wc -l)"; \
    if [ "$installer_count" -ne 1 ]; then \
        echo "ERROR: jar/ must contain exactly one Forge installer JAR."; \
        find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' -print; \
        exit 1; \
    fi; \
    installer="$(find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' | head -n 1)"; \
    cd /opt/minecraft/server-template; \
    java -jar "$installer" --installServer; \
    rm -rf /tmp/forge-installer

WORKDIR /data

EXPOSE 25565/tcp
EXPOSE 25575/tcp

VOLUME ["/data"]

ENV EULA=FALSE
ENV JVM_XMS=2G
ENV JVM_XMX=6G
ENV JVM_ARGS=""
ENV ENABLE_RCON=TRUE
ENV RCON_PORT=25575
ENV RCON_PASSWORD="change-this-rcon-password"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
