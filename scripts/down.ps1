# down.ps1 (Versão Robusta)
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [string]$env,

    [string]$tag = "latest"
)

$ErrorActionPreference = 'Stop'

# Paths
$envFile = ".\environments\${env}\.env"
$overrideFile = ".\environments\${env}\docker-compose.override.yml"

if (-not (Test-Path $envFile)) {
    Write-Error "ERRO: Arquivo de env não encontrado: $envFile"
    exit 1
}

# Passa TAG para o compose (se necessário)
$env:TAG = $tag

Write-Host "INFO: Parando o ambiente '$env' de forma controlada..."

# Monta args do compose principal
$composeArgs = @(
    "--env-file", $envFile,
    "-f", "docker-compose.yml"
)

if (Test-Path $overrideFile) {
    $composeArgs += @("-f", $overrideFile)
} else {
    Write-Host "AVISO: Override não encontrado: $overrideFile (prosseguindo sem ele)"
}

try {
    # Passo 1: Derrubar a aplicação principal
    docker compose @composeArgs down --remove-orphans

    # Passo 2: Derrubar o proxy (se existir)
    if (Test-Path "proxy-compose.yml") {
        docker compose --env-file $envFile -f "proxy-compose.yml" down --remove-orphans
    } else {
        Write-Host "AVISO: proxy-compose.yml não encontrado; pulando proxy."
    }

    Write-Host "SUCESSO: Ambiente '$env' parado."

} catch {
    Write-Error "ERRO: Falha ao parar o ambiente. $_"
    exit 1
}
