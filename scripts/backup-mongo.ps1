# backup-mongo.ps1
# Faz backup do MongoDB usando mongodump e mantém os últimos N dias
param (
    [string]$backupDir = "",
    [string]$container = "amg-infra-database-1",
    [int]$keepDays = 7
)

# Define o diretório de backup relativo à raiz do repositório se não informado
if (-not $backupDir) {
    $backupDir = Join-Path (Split-Path -Parent $PSScriptRoot) "Backups\MongoDB"
}

$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$backupPath = "$backupDir\$timestamp"

# Criar pasta de destino
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Verificar se o container está rodando
$running = docker inspect --format '{{.State.Running}}' $container 2>$null
if ($running -ne 'true') {
    Write-Error "ERRO: Container '$container' não está rodando."
    exit 1
}

Write-Host "INFO: Iniciando backup em '$backupPath'..."

# Executar mongodump dentro do container e copiar para o host
docker exec $container mongodump --out /tmp/mongodump-$timestamp --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERRO: Falha ao executar mongodump."
    exit 1
}

# Copiar o dump do container para o host
docker cp "${container}:/tmp/mongodump-$timestamp" $backupPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERRO: Falha ao copiar backup do container."
    exit 1
}

# Limpar o dump dentro do container
docker exec $container rm -rf /tmp/mongodump-$timestamp

Write-Host "SUCESSO: Backup salvo em '$backupPath'"

# Remover backups antigos (mais de $keepDays dias)
$cutoff = (Get-Date).AddDays(-$keepDays)
Get-ChildItem -Path $backupDir -Directory | Where-Object { $_.CreationTime -lt $cutoff } | ForEach-Object {
    Write-Host "INFO: Removendo backup antigo: $($_.FullName)"
    Remove-Item -Recurse -Force $_.FullName
}

Write-Host "INFO: Backups mantidos: $keepDays dias"
