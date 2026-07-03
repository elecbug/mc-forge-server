# syntax=docker/dockerfile:1

# Change the Java image to match your Minecraft/Forge version.
# For example:
# - MC 1.18 ~ 1.20.4 series: eclipse-temurin:17-jre-jammy
# - MC 1.20.5+ / 1.21+ series: eclipse-temurin:21-jre-jammy
ARG JAVA_IMAGE=eclipse-temurin:21-jre-jammy

FROM ${JAVA_IMAGE}

ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} minecraft \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash minecraft

WORKDIR /tmp/forge-installer

COPY jar/*.jar /tmp/forge-installer/

RUN set -eux; \
    installer_count="$(find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' | wc -l)"; \
    if [ "$installer_count" -ne 1 ]; then \
        echo "ERROR: jar/ must contain exactly one Forge installer JAR."; \
        find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' -print; \
        exit 1; \
    fi; \
    installer="$(find /tmp/forge-installer -maxdepth 1 -type f -name '*.jar' | head -n 1)"; \
    mkdir -p /opt/minecraft/server-template; \
    cd /opt/minecraft/server-template; \
    java -jar "$installer" --installServer; \
    rm -rf /tmp/forge-installer

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /data \
    && chown -R minecraft:minecraft /opt/minecraft /data

USER minecraft

WORKDIR /data

EXPOSE 25565/tcp
EXPOSE 25575/tcp

VOLUME ["/data"]

ENV EULA=FALSE
ENV JVM_XMS=2G
ENV JVM_XMX=6G
ENV JVM_ARGS=""

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]