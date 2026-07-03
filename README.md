# Minecraft Forge Docker + RCON 운영 구조

## 파일 구조

```text
.
├─ Dockerfile
├─ docker-compose.yml
├─ entrypoint.sh
├─ .env.example
├─ mcctl.sh
├─ mcctl.ps1
├─ backup.sh
├─ jar/
│  └─ forge-...-installer.jar
└─ data/
```

## 1. 설정

```bash
cp .env.example .env
```

`.env`에서 `RCON_PASSWORD`, `JVM_XMX`, `MEM_LIMIT`, `JAVA_IMAGE`를 환경에 맞게 수정하십시오.

## 2. 실행

```bash
docker compose build
docker compose up -d
docker compose logs -f
```

## 3. RCON 명령

Linux/macOS/WSL/Git Bash:

```bash
chmod +x mcctl.sh backup.sh
./mcctl.sh "op 닉네임"
./mcctl.sh "whitelist add 닉네임"
./mcctl.sh "say 서버 공지"
./mcctl.sh "save-all"
./mcctl.sh "list"
```

Windows PowerShell:

```powershell
.\mcctl.ps1 "op 닉네임"
.\mcctl.ps1 "say 서버 공지"
.\mcctl.ps1 "list"
```

## 4. 백업

```bash
./backup.sh
```

백업 파일은 `data/backups/`에 생성됩니다.

## 5. 보안 구조

- Minecraft 접속 포트 `25565`만 호스트에 공개합니다.
- RCON 포트 `25575`는 호스트에 공개하지 않습니다.
- `mcctl.sh`와 `mcctl.ps1`은 임시 `itzg/rcon-cli` 컨테이너를 `mc-forge` 네트워크 네임스페이스에 붙여 RCON 명령을 실행합니다.
- 따라서 `docker attach`를 사용할 필요가 없습니다.


## Windows CMD RCON wrapper

PowerShell execution policy may block `mcctl.ps1`. In that case, use `mcctl.cmd` from Command Prompt, Windows Terminal, or the VS Code terminal:

```bat
mcctl.cmd list
mcctl.cmd op Steve
mcctl.cmd say Server will restart in 5 minutes
mcctl.cmd save-all
```

The script reads `.env`, attaches an ephemeral `itzg/rcon-cli` container to the Minecraft container network, and sends the RCON command without exposing the RCON port to the host.
