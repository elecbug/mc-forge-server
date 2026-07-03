param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$CommandParts
)

$envFile = ".env"

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) {
            return
        }

        $parts = $line -split "=", 2
        if ($parts.Length -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim().Trim('"').Trim("'")
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$containerName = if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "mc-forge" }
$rconPort = if ($env:RCON_PORT) { $env:RCON_PORT } else { "25575" }
$rconPassword = if ($env:RCON_PASSWORD) { $env:RCON_PASSWORD } else { "change-this-rcon-password" }
$command = $CommandParts -join " "

if (-not $command) {
    Write-Error "Usage: .\mcctl.ps1 \"minecraft command\""
    exit 1
}

docker inspect $containerName *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Container '$containerName' does not exist or is not accessible."
    exit 1
}

docker run --rm -i `
    --network "container:$containerName" `
    itzg/rcon-cli `
    --host 127.0.0.1 `
    --port $rconPort `
    --password $rconPassword `
    $command
