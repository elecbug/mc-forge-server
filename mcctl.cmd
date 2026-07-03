@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Minecraft RCON command wrapper for Windows CMD.
REM Usage:
REM   mcctl.cmd op Steve
REM   mcctl.cmd say Server will restart in 5 minutes
REM   mcctl.cmd save-all

if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        set "KEY=%%A"
        set "VALUE=%%B"

        REM Ignore comments and empty keys.
        if not "!KEY!"=="" if not "!KEY:~0,1!"=="#" (
            set "!KEY!=!VALUE!"
        )
    )
)

if "%CONTAINER_NAME%"=="" set "CONTAINER_NAME=mc-forge"
if "%RCON_PORT%"=="" set "RCON_PORT=25575"
if "%RCON_PASSWORD%"=="" set "RCON_PASSWORD=change-this-rcon-password"

if "%~1"=="" (
    echo Usage: %~nx0 minecraft command
    echo Example: %~nx0 op Steve
    echo Example: %~nx0 say Server will restart in 5 minutes
    exit /b 1
)

set "MC_COMMAND=%*"

docker inspect "%CONTAINER_NAME%" >nul 2>nul
if errorlevel 1 (
    echo ERROR: Container "%CONTAINER_NAME%" does not exist or is not accessible.
    exit /b 1
)

docker run --rm -i ^
    --network "container:%CONTAINER_NAME%" ^
    itzg/rcon-cli ^
    --host 127.0.0.1 ^
    --port "%RCON_PORT%" ^
    --password "%RCON_PASSWORD%" ^
    "!MC_COMMAND!"

exit /b %ERRORLEVEL%
