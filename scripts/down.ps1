# down.ps1
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [Alias('env')]
    [string]$environment,

    [string]$tag = "latest"
)

$ErrorActionPreference = 'Stop'

# Paths
$envFile = ".\environments\${environment}\.env"
$overrideFile = ".\environments\${environment}\docker-compose.override.yml"

if (-not (Test-Path $envFile)) {
    Write-Error "ERRO: Arquivo de env não encontrado: $envFile"
    exit 1
}

$env:TAG = $tag

# Nome do projeto Docker Compose (deve bater com o usado no up.ps1)
$projectName = if ($environment -eq 'dev') { 'amg-infra-dev' } else { 'amg-infra' }

Write-Host "INFO: Parando o ambiente '$environment' de forma controlada..."

# Monta args do compose principal
$composeArgs = @(
    "--project-name", $projectName,
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

    # Passo 2: Derrubar o proxy — dev não derruba o proxy (é compartilhado com prod)
    if ($environment -ne 'dev' -and (Test-Path "proxy-compose.yml")) {
        $proxyEnvFile = $envFile
        docker compose --project-name amg-infra --env-file $proxyEnvFile -f "proxy-compose.yml" down --remove-orphans
    } elseif ($environment -eq 'dev') {
        Write-Host "INFO: Proxy mantido (compartilhado com prod)."
    }

    Write-Host "SUCESSO: Ambiente '$environment' parado."

} catch {
    Write-Error "ERRO: Falha ao parar o ambiente. $_"
    exit 1
}
