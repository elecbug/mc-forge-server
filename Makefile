# Minecraft Forge Docker Server Makefile
# Cross-platform: Windows CMD / Linux / WSL / macOS
#
# Required files
# - docker-compose.yml
# - .env
# - Windows: mcctl.cmd
# - Linux/WSL/macOS: mcctl.sh
# - data/

COMPOSE := docker compose
CONTAINER := mc-forge

ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
	SHELL := cmd.exe
	.SHELLFLAGS := /C
	RCON := mcctl.cmd
	BACKUP_DIR := data\backups
	STAMP := $(shell powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss")
	BACKUP_FILE := $(BACKUP_DIR)\mc-forge-$(STAMP).zip
	MKDIR_BACKUP := if not exist "$(BACKUP_DIR)" mkdir "$(BACKUP_DIR)"
	BACKUP_CMD := tar -a -cf "$(BACKUP_FILE)" --exclude data\backups --exclude data\logs data
	CLEAN_LOGS := if exist data\logs del /Q data\logs\*
	SLEEP_10 := timeout /T 10 /NOBREAK >nul
else
	IS_WINDOWS := 0
	SHELL := /usr/bin/env bash
	RCON := ./mcctl.sh
	BACKUP_DIR := data/backups
	STAMP := $(shell date +%Y%m%d-%H%M%S)
	BACKUP_FILE := $(BACKUP_DIR)/mc-forge-$(STAMP).tar.gz
	MKDIR_BACKUP := mkdir -p "$(BACKUP_DIR)"
	BACKUP_CMD := tar --exclude='data/backups' --exclude='data/logs' -czf "$(BACKUP_FILE)" data
	CLEAN_LOGS := rm -rf data/logs/*
	SLEEP_10 := sleep 10
endif

.PHONY: help chmod start up logs ps status list rcon save stop down restart force-stop kill backup save-backup stop-backup clean-logs

help:
	@echo.
	@echo Minecraft Forge Server Commands
	@echo --------------------------------
	@echo make chmod        - chmod +x scripts on Linux/WSL/macOS
	@echo make start        - Start server in background
	@echo make logs         - Follow server logs
	@echo make ps           - Show container status
	@echo make list         - Show online players through RCON
	@echo make save         - Save world
	@echo make stop         - Save and gracefully stop Minecraft server
	@echo make restart      - Save, stop, then start server
	@echo make force-stop   - Stop Docker container directly
	@echo make kill         - Force kill container
	@echo make backup       - Backup data folder
	@echo make save-backup  - Save world, then backup
	@echo make stop-backup  - Save, backup, then gracefully stop
	@echo make clean-logs   - Delete data/logs content
	@echo.
	@echo RCON direct command:
	@echo make rcon CMD="say hello"
	@echo.

chmod:
ifeq ($(IS_WINDOWS),1)
	@echo chmod is not needed on Windows.
else
	chmod +x mcctl.sh || true
	chmod +x backup.sh || true
endif

start:
	$(COMPOSE) up -d

up: start

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

status: ps

list:
ifeq ($(IS_WINDOWS),1)
	$(RCON) list
else
	$(RCON) "list"
endif

rcon:
ifeq ($(IS_WINDOWS),1)
	@if "$(CMD)"=="" (echo Usage: make rcon CMD="say hello" && exit /b 1)
	$(RCON) $(CMD)
else
	@if [ -z "$(CMD)" ]; then echo 'Usage: make rcon CMD="say hello"'; exit 1; fi
	$(RCON) "$(CMD)"
endif

save:
ifeq ($(IS_WINDOWS),1)
	$(RCON) save-all
else
	$(RCON) "save-all"
endif

stop:
ifeq ($(IS_WINDOWS),1)
	$(RCON) save-all
	$(RCON) stop
else
	$(RCON) "save-all"
	$(RCON) "stop"
endif

down:
	$(COMPOSE) down

restart:
ifeq ($(IS_WINDOWS),1)
	$(RCON) save-all
	$(RCON) stop
	$(SLEEP_10)
	$(COMPOSE) up -d
else
	$(RCON) "save-all"
	$(RCON) "stop"
	$(SLEEP_10)
	$(COMPOSE) up -d
endif

force-stop:
	$(COMPOSE) stop -t 120

kill:
	docker kill $(CONTAINER)

backup:
	$(MKDIR_BACKUP)
	$(BACKUP_CMD)
	@echo Backup created: $(BACKUP_FILE)

save-backup:
ifeq ($(IS_WINDOWS),1)
	$(RCON) save-all
else
	$(RCON) "save-all"
endif
	$(MKDIR_BACKUP)
	$(BACKUP_CMD)
	@echo Backup created: $(BACKUP_FILE)

stop-backup:
ifeq ($(IS_WINDOWS),1)
	$(RCON) save-all
else
	$(RCON) "save-all"
endif
	$(MKDIR_BACKUP)
	$(BACKUP_CMD)
	@echo Backup created: $(BACKUP_FILE)
ifeq ($(IS_WINDOWS),1)
	$(RCON) stop
else
	$(RCON) "stop"
endif

clean-logs:
	$(CLEAN_LOGS)