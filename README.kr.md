# Minecraft Forge Docker 서버

Docker 기반 Minecraft Forge 전용 서버 구성입니다. RCON, 영구 데이터 저장, 안전 종료, 백업, 그리고 Windows/Linux/macOS/WSL에서 모두 사용할 수 있는 Makefile을 포함합니다.

이 구성은 모드 서버를 반복 가능하고 깔끔하게 운영하기 위한 구조입니다. 월드, 모드, 설정, 로그, 백업 데이터는 컨테이너 외부의 `data/` 디렉터리에 보존됩니다.

---

## 주요 기능

* Docker Compose 기반 Forge 서버
* `data/` 디렉터리를 통한 영구 저장
* RCON 기반 서버 관리
* OS 자동 감지 Makefile

  * Windows: `mcctl.cmd` 사용
  * Linux/macOS/WSL: `mcctl.sh` 사용
* 안전한 저장 및 종료 명령
* 백업 명령 제공
* RCON을 통한 화이트리스트 및 OP 관리
* `docker attach` 없이 서버 명령 실행 가능
* Forge 모드 서버 운영에 적합

---

## 디렉터리 구조

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

`data/` 디렉터리가 실제 Minecraft 서버 루트입니다. 컨테이너가 재생성되어도 이 디렉터리의 월드, 모드, 설정 파일은 유지됩니다.

---

## 요구사항

### 공통 요구사항

* Docker
* Docker Compose
* `jar/` 디렉터리에 Forge installer JAR 배치
* 서버와 동일한 Minecraft, Forge, 모드 버전을 사용하는 Minecraft Java Edition 클라이언트

### Windows 요구사항

* Docker Desktop
* Makefile을 사용할 경우 GNU Make 필요

  * Git Bash, MSYS2, Chocolatey, Scoop 등으로 설치 가능

### Linux / macOS / WSL 요구사항

* Docker Engine 또는 Docker Desktop
* GNU Make
* Bash
* `tar`

---

## 설치 및 실행

### 1. Forge Installer 배치

Forge installer JAR 파일을 `jar/` 디렉터리에 넣습니다.

예시:

```text
jar/forge-1.20.1-47.4.10-installer.jar
```

일반적으로 이 디렉터리에는 Forge installer JAR 하나만 두는 것이 좋습니다.

---

### 2. 환경 파일 생성

예시 환경 파일을 복사합니다.

```bash
cp .env.example .env
```

Windows CMD에서는:

```bat
copy .env.example .env
```

그다음 `.env`를 수정합니다.

예시:

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

`RCON_PASSWORD`는 반드시 길고 예측하기 어려운 값으로 바꾸십시오.

---

### 3. 이미지 빌드

```bash
docker compose build --no-cache
```

---

### 4. 서버 시작

```bash
docker compose up -d
```

또는 Makefile을 사용합니다.

```bash
make start
```

로그 확인:

```bash
make logs
```

아래와 같은 로그가 나오면 서버가 정상적으로 열린 것입니다.

```text
Done (...)! For help, type "help"
```

---

## 서버 관리

이 구성은 Minecraft 서버 관리를 RCON으로 수행합니다. 일반적으로 `docker attach`를 사용할 필요가 없습니다.

### 접속 중인 플레이어 확인

```bash
make list
```

### RCON 명령 직접 실행

```bash
make rcon CMD="say Hello players"
make rcon CMD="whitelist list"
make rcon CMD="op PlayerName"
```

### 월드 저장

```bash
make save
```

### 안전 종료

```bash
make stop
```

이 명령은 내부적으로 다음을 실행합니다.

```text
save-all
stop
```

단순히 Docker 컨테이너를 죽이는 것보다 안전합니다.

### 재시작

```bash
make restart
```

### 컨테이너 직접 종료

```bash
make force-stop
```

RCON이 동작하지 않을 때만 사용하는 편이 좋습니다.

### 강제 종료

```bash
make kill
```

최후의 수단으로만 사용하십시오. 월드 저장이나 모드 종료 훅이 정상 처리되지 않을 수 있습니다.

---

## 백업

### 백업 생성

```bash
make backup
```

### 저장 후 백업

```bash
make save-backup
```

### 저장, 백업, 종료

```bash
make stop-backup
```

백업 파일은 다음 위치에 생성됩니다.

```text
data/backups/
```

기본적으로 백업에서 제외되는 경로는 다음입니다.

```text
data/backups/
data/logs/
```

---

## 화이트리스트 관리

개인 서버라면 화이트리스트 사용을 권장합니다.

### 화이트리스트 켜기

```bash
make rcon CMD="whitelist on"
```

### 플레이어 추가

```bash
make rcon CMD="whitelist add PlayerName"
```

### 플레이어 제거

```bash
make rcon CMD="whitelist remove PlayerName"
```

### 화이트리스트 다시 불러오기

```bash
make rcon CMD="whitelist reload"
```

### 화이트리스트 목록 확인

```bash
make rcon CMD="whitelist list"
```

화이트리스트가 켜져 있으면 목록에 없는 플레이어는 서버에 접속할 수 없습니다.

---

## OP 관리

### OP 추가

```bash
make rcon CMD="op PlayerName"
```

### OP 제거

```bash
make rcon CMD="deop PlayerName"
```

화이트리스트와 OP는 별개입니다. 개인 서버에서는 본인을 둘 다 등록하는 것이 좋습니다.

```bash
make rcon CMD="whitelist add PlayerName"
make rcon CMD="op PlayerName"
```

---

## 모드 관리

서버용 모드는 다음 위치에 넣습니다.

```text
data/mods/
```

모드 설정 파일은 다음 위치에 넣습니다.

```text
data/config/
```

클라이언트는 서버와 동일한 Minecraft 버전, Forge 버전, 필수 모드 구성을 사용해야 합니다.

### 중요: 클라이언트 전용 모드

렌더링, 셰이더, 미니맵, HUD 등 클라이언트 전용 모드는 서버 `mods/`에 넣으면 안 됩니다.

대표적인 예시는 다음과 같습니다.

```text
Oculus
Embeddium
Rubidium
JourneyMap
Dynamic Lights
셰이더 관련 모드
클라이언트 미니맵 모드
클라이언트 HUD 모드
```

이런 모드는 보통 클라이언트의 `.minecraft/mods`에만 넣어야 합니다.

클라이언트 전용 모드를 서버에 넣으면 다음과 같은 오류가 발생할 수 있습니다.

```text
Attempted to load class net/minecraft/client/... for invalid dist DEDICATED_SERVER
```

이 오류가 나오면 해당 클라이언트 전용 모드를 `data/mods/`에서 제거하십시오.

---

## 설정 파일

Minecraft 서버 설정은 다음 파일에 저장됩니다.

```text
data/server.properties
```

자주 사용하는 설정은 다음과 같습니다.

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

일부 값은 직접 수정할 수 있지만, RCON 관련 설정은 `.env`와 `entrypoint.sh`를 통해 자동으로 주입됩니다.

---

## RCON 보안

RCON은 서버 관리를 위해 컨테이너 내부에서 활성화됩니다.

권장 사항은 다음과 같습니다.

* RCON 포트를 인터넷에 공개하지 마십시오.
* 긴 랜덤 비밀번호를 사용하십시오.
* `.env`를 공개 저장소에 올리지 마십시오.
* 외부에는 Minecraft 접속 포트, 보통 `25565`만 여십시오.

권장되는 Docker Compose 구조는 Minecraft 포트만 공개합니다.

```yaml
ports:
  - "25565:25565"
```

RCON은 `mcctl.sh` 또는 `mcctl.cmd`를 통해 내부적으로 접근하는 방식이 안전합니다.

---

## 주요 Make 명령

```text
make help          명령 목록 출력
make start         서버 시작
make logs          로그 확인
make ps            컨테이너 상태 확인
make list          접속 중인 플레이어 확인
make save          월드 저장
make stop          저장 후 정상 종료
make restart       저장, 종료, 재시작
make backup        백업 생성
make save-backup   저장 후 백업
make stop-backup   저장, 백업, 종료
make force-stop    Docker stop으로 종료
make kill          컨테이너 강제 종료
make clean-logs    로그 파일 삭제
```

---

## 문제 해결

### `/usr/bin/env: 'bash\r': No such file or directory`

스크립트가 Windows CRLF 줄바꿈으로 저장된 경우입니다.

LF로 변환합니다.

```bash
sed -i 's/\r$//' entrypoint.sh
sed -i 's/\r$//' mcctl.sh
```

또는 VS Code 오른쪽 아래에서 줄바꿈을 `CRLF`에서 `LF`로 바꾸고 저장하십시오.

---

### `missing mods.toml file`

Forge 내부 라이브러리에 대해 다음과 같은 경고가 나올 수 있습니다.

```text
fmlcore
javafmllanguage
lowcodelanguage
mclanguage
```

서버가 계속 부팅되어 `Done`까지 도달한다면 보통 무시해도 됩니다.

---

### `invalid dist DEDICATED_SERVER`

대부분 클라이언트 전용 모드를 서버에 넣었을 때 발생합니다.

문제가 되는 모드를 다음 위치에서 제거하십시오.

```text
data/mods/
```

렌더링, 셰이더, 미니맵, HUD, 클라이언트 최적화 모드가 흔한 원인입니다.

---

### 모드 로딩 중 서버 크래시

다음 파일을 확인하십시오.

```text
data/logs/latest.log
data/crash-reports/
```

흔한 원인은 다음과 같습니다.

* Minecraft 버전 불일치
* Forge 버전 불일치
* 의존성 모드 누락
* Forge 서버에 Fabric/Quilt 모드 사용
* 서버에 클라이언트 전용 모드 설치
* 모드팩의 `config/` 파일 누락
* RAM 부족

---

### RCON이 동작하지 않을 때

먼저 서버가 완전히 부팅되었는지 확인하십시오.

그다음 `.env`를 확인합니다.

```env
ENABLE_RCON=TRUE
RCON_PORT=25575
RCON_PASSWORD=your_password
```

컨테이너 상태 확인:

```bash
make ps
```

로그 확인:

```bash
make logs
```

---

## 권장 JVM 설정

무거운 Forge 모드팩에서는 서버 전체 메모리를 전부 Java에 할당하지 않는 것이 좋습니다.

16GB 서버 예시:

```env
JVM_XMS=4G
JVM_XMX=10G
MEM_LIMIT=12g
```

더 무거운 서버 예시:

```env
JVM_XMS=6G
JVM_XMX=12G
MEM_LIMIT=14g
```

운영체제, Docker, 파일 캐시, Java native memory, 모드 내부 메모리를 위해 여유 메모리를 남겨두는 것이 안정적입니다.

---

## 권장 운영 흐름

### 서버 시작

```bash
make start
make logs
```

### 점검 전

```bash
make rcon CMD="say Server maintenance will start soon"
make save-backup
```

### 종료

```bash
make stop
```

### 백업 후 종료

```bash
make stop-backup
```

---

## 주의

아래 명령은 의미를 정확히 이해하지 못한 상태에서는 사용하지 않는 것이 좋습니다.

```bash
docker compose down -v
```

`-v` 옵션은 Docker volume을 삭제할 수 있습니다. 월드 데이터가 Docker volume에 저장되어 있는 구조라면 서버 데이터가 삭제될 수 있습니다.

---

## 라이선스

이 구성은 개인 Minecraft 서버 운영 목적에 맞게 자유롭게 수정해서 사용할 수 있습니다.
