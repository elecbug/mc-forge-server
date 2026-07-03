# Minecraft Forge Docker Server

A Docker-based Minecraft Forge dedicated server setup with RCON support, persistent data storage, safe shutdown commands, backups, and a cross-platform Makefile for both Windows and Linux/macOS/WSL environments.

This project is designed for running a modded Minecraft Forge server in a clean and repeatable way while keeping world data, mods, configs, logs, and backups outside the container.

---

## Features

* Docker Compose based Forge server
* Persistent `data/` directory
* RCON enabled for safe server administration
* Cross-platform `Makefile`

  * Windows: uses `mcctl.cmd`
  * Linux/macOS/WSL: uses `mcctl.sh`
* Safe save and shutdown commands
* Backup commands
* Whitelist and OP management through RCON
* No need to use `docker attach` for server commands
* Suitable for modded Forge servers

---

## Directory Structure

```text
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── Makefile
├── .env
├── .env.example
├── mcctl.sh
├── mcctl.cmd
├── mcctl.ps1
├── backup.sh
├── jar/
│   └── forge-installer.jar
└── data/
    ├── mods/
    ├── config/
    ├── world/
    ├── logs/
    ├── backups/
    ├── server.properties
    ├── whitelist.json
    └── ops.json
```

The `data/` directory is the actual Minecraft server directory. It is mounted into the container and persists even if the container is recreated.

---

## Requirements

### Common Requirements

* Docker
* Docker Compose
* A Forge installer JAR placed under `jar/`
* Minecraft Java Edition client with the same Minecraft, Forge, and mod versions

### Windows Requirements

* Docker Desktop
* GNU Make if you want to use the `Makefile`

  * Git Bash, MSYS2, Chocolatey, Scoop, or similar tools can provide `make`

### Linux / macOS / WSL Requirements

* Docker Engine or Docker Desktop
* GNU Make
* Bash
* `tar`

---

## Setup

### 1. Place the Forge Installer

Put your Forge installer JAR in the `jar/` directory.

Example:

```text
jar/forge-1.20.1-47.4.10-installer.jar
```

Only one Forge installer JAR should normally be placed in this directory.

---

### 2. Create the Environment File

Copy the example environment file:

```bash
cp .env.example .env
```

On Windows CMD:

```bat
copy .env.example .env
```

Edit `.env` and configure the values.

Example:

```env
EULA=TRUE

JVM_XMS=4G
JVM_XMX=10G
JVM_ARGS=-XX:+UseG1GC

MEM_LIMIT=12g

SERVER_PORT=25565

ENABLE_RCON=TRUE
RCON_PORT=25575
RCON_PASSWORD=change_this_to_a_long_random_password
```

Do not use a weak RCON password.

---

### 3. Build the Image

```bash
docker compose build --no-cache
```

---

### 4. Start the Server

```bash
docker compose up -d
```

Or with the Makefile:

```bash
make start
```

Follow the logs:

```bash
make logs
```

The server is ready when you see a message like:

```text
Done (...)! For help, type "help"
```

---

## Managing the Server

This project uses RCON for Minecraft server administration. You should not normally use `docker attach`.

### Check Online Players

```bash
make list
```

### Send a Raw RCON Command

```bash
make rcon CMD="say Hello players"
make rcon CMD="whitelist list"
make rcon CMD="op PlayerName"
```

### Save the World

```bash
make save
```

### Safely Stop the Server

```bash
make stop
```

This runs:

```text
save-all
stop
```

This is safer than directly killing the Docker container.

### Restart the Server

```bash
make restart
```

### Force Stop the Container

```bash
make force-stop
```

This sends a Docker stop signal with a grace period. Use this only when RCON is unavailable.

### Kill the Container

```bash
make kill
```

Use this only as a last resort. It may interrupt world saving or mod shutdown hooks.

---

## Backups

### Create a Backup

```bash
make backup
```

### Save and Backup

```bash
make save-backup
```

### Save, Backup, and Stop

```bash
make stop-backup
```

Backups are stored in:

```text
data/backups/
```

By default, backups exclude:

```text
data/backups/
data/logs/
```

---

## Whitelist Management

Whitelist is recommended for private servers.

### Enable Whitelist

```bash
make rcon CMD="whitelist on"
```

### Add a Player

```bash
make rcon CMD="whitelist add PlayerName"
```

### Remove a Player

```bash
make rcon CMD="whitelist remove PlayerName"
```

### Reload Whitelist

```bash
make rcon CMD="whitelist reload"
```

### List Whitelisted Players

```bash
make rcon CMD="whitelist list"
```

If whitelist is enabled, players who are not on the whitelist cannot join the server.

---

## OP Management

### Add an Operator

```bash
make rcon CMD="op PlayerName"
```

### Remove an Operator

```bash
make rcon CMD="deop PlayerName"
```

Whitelist and OP are separate. For private servers, add yourself to both:

```bash
make rcon CMD="whitelist add PlayerName"
make rcon CMD="op PlayerName"
```

---

## Mod Management

Server-side mods should be placed in:

```text
data/mods/
```

Config files should be placed in:

```text
data/config/
```

The client must use the same Minecraft version, Forge version, and required mod set.

### Important: Client-Only Mods

Do not put client-only rendering or UI mods in the server `mods/` directory.

Common examples include:

```text
Oculus
Embeddium
Rubidium
JourneyMap
Dynamic Lights
shader-related mods
client-side minimap mods
client-side HUD mods
```

These should usually be installed only on the client.

A common crash caused by client-only mods looks like:

```text
Attempted to load class net/minecraft/client/... for invalid dist DEDICATED_SERVER
```

If you see this error, remove the client-only mod from `data/mods/`.

---

## Configuration

Minecraft server settings are stored in:

```text
data/server.properties
```

Useful settings include:

```properties
white-list=true
online-mode=true
motd=A Minecraft Forge Server
max-players=20
view-distance=8
simulation-distance=6
enable-rcon=true
rcon.port=25575
```

Most of these values can be edited directly, but RCON settings are also managed by the entrypoint script using `.env`.

---

## RCON Security

RCON is enabled inside the container for administration.

Recommended rules:

* Do not expose RCON to the public internet.
* Use a long random password.
* Do not commit `.env` to a public repository.
* Only expose the Minecraft server port, usually `25565`.

The recommended Docker Compose structure exposes only the Minecraft port:

```yaml
ports:
  - "25565:25565"
```

RCON should be accessed internally through `mcctl.sh` or `mcctl.cmd`.

---

## Useful Make Commands

```text
make help          Show command list
make start         Start server
make logs          Follow logs
make ps            Show container status
make list          Show online players
make save          Save world
make stop          Save and gracefully stop
make restart       Save, stop, and start again
make backup        Create backup
make save-backup   Save world and create backup
make stop-backup   Save, backup, and stop
make force-stop    Docker stop with timeout
make kill          Force kill container
make clean-logs    Remove log files
```

---

## Troubleshooting

### `/usr/bin/env: 'bash\r': No such file or directory`

The script has Windows CRLF line endings.

Convert the file to LF:

```bash
sed -i 's/\r$//' entrypoint.sh
sed -i 's/\r$//' mcctl.sh
```

Or change the line ending to `LF` in VS Code.

---

### `missing mods.toml file`

Warnings like this for Forge internal libraries are usually harmless:

```text
fmlcore
javafmllanguage
lowcodelanguage
mclanguage
```

If the server continues to `Done`, it is not a problem.

---

### `invalid dist DEDICATED_SERVER`

This usually means a client-only mod is installed on the server.

Remove the problematic mod from:

```text
data/mods/
```

Common candidates are rendering, shader, minimap, HUD, or client optimization mods.

---

### Server Crashes During Mod Loading

Check:

```text
data/logs/latest.log
data/crash-reports/
```

Common causes:

* Wrong Minecraft version
* Wrong Forge version
* Missing dependency mod
* Fabric/Quilt mod used on Forge
* Client-only mod installed on server
* Missing config files from a modpack
* Insufficient RAM

---

### RCON Does Not Work

Check that the server has fully started.

Then verify `.env`:

```env
ENABLE_RCON=TRUE
RCON_PORT=25575
RCON_PASSWORD=your_password
```

Check container status:

```bash
make ps
```

Check logs:

```bash
make logs
```

---

## Recommended JVM Settings

For a heavy Forge modpack, do not assign all system memory to Java.

Example for a 16GB server:

```env
JVM_XMS=4G
JVM_XMX=10G
MEM_LIMIT=12g
```

For a heavier server:

```env
JVM_XMS=6G
JVM_XMX=12G
MEM_LIMIT=14g
```

Leave memory for the operating system, Docker, file cache, and native memory used by Java and mods.

---

## Safe Operation Workflow

### Start

```bash
make start
make logs
```

### Before Maintenance

```bash
make rcon CMD="say Server maintenance will start soon"
make save-backup
```

### Shutdown

```bash
make stop
```

### Shutdown with Backup

```bash
make stop-backup
```

---

## Warning

Avoid this command unless you fully understand the consequences:

```bash
docker compose down -v
```

The `-v` option may remove Docker volumes. If your world is stored in a Docker volume instead of a bind-mounted `data/` directory, this can delete server data.

---

## License

Use and modify this setup as needed for your own Minecraft server.
