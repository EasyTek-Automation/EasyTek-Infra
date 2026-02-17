# easytek-infra/scripts/build-and-push.ps1 (Versão Definitiva)
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$tag
)

# Função para carregar variáveis do arquivo .env
function Load-EnvFile {
    param([string]$EnvFilePath)

    if (Test-Path $EnvFilePath) {
        Write-Host "INFO: Carregando variáveis do arquivo .env..."
        Get-Content $EnvFilePath | ForEach-Object {
            $line = $_.Trim()
            # Ignora linhas vazias e comentários
            if ($line -and -not $line.StartsWith('#')) {
                $parts = $line -split '=', 2
                if ($parts.Count -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    # Remove aspas se existirem
                    $value = $value -replace '^["'']|["'']$', ''
                    [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
                }
            }
        }
    }
}

# Carrega o arquivo .env da raiz do projeto (se existir)
$rootPath = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $rootPath ".env"
Load-EnvFile -EnvFilePath $envFile

Write-Host "INFO: Iniciando build multi-arquitetura para a versão '$tag'..."

# Validação de pré-requisitos
if (-not $env:GITHUB_USER -or -not $env:GITHUB_PAT) {
    Write-Error "ERRO: As variáveis de ambiente GITHUB_USER e GITHUB_PAT devem ser definidas no arquivo .env ou como variáveis de ambiente do sistema."
    exit 1
}

# Autenticação
Write-Host "INFO: Autenticando no ghcr.io..."
$env:GITHUB_PAT | docker login ghcr.io -u $env:GITHUB_USER --password-stdin
if ($LASTEXITCODE -ne 0) { throw "Falha na autenticação com o ghcr.io." }

# Define o caminho RELATIVO para a pasta de código a partir da raiz de 'easytek-infra'
$CodePath = "E:\Projetos Python\AMG_Data"

# Lista de serviços a serem construídos
$services = @("webapp", "event-gateway", "zpp-processor", "node-red", "amg-mobile")

# Loop para construir e enviar cada serviço
foreach ($service in $services) {
    $imageName = "ghcr.io/easytek-automation/easytek-data/$service`:$tag"
    
    # Caminho para a pasta do serviço (o contexto do build)
    $contextPath = Join-Path $CodePath $service
    
    # Caminho explícito para o Dockerfile
    $dockerfilePath = Join-Path $contextPath "Dockerfile"

    Write-Host "--------------------------------------------------"
    Write-Host "Construindo e enviando $imageName..."
    Write-Host "  -> Usando Dockerfile: $dockerfilePath"
    Write-Host "  -> Usando Contexto:   $contextPath"
    Write-Host "--------------------------------------------------"

    # Comando corrigido:
    # - Usa a flag '-f' para especificar o Dockerfile.
    # - O último argumento é o contexto do build.
    docker buildx build --platform linux/amd64,linux/arm64 -t $imageName --file $dockerfilePath --push $contextPath

    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERRO: Falha ao construir a imagem para o serviço '$service'. Abortando."
        exit 1
    }
}

Write-Host "--------------------------------------------------"
Write-Host "SUCESSO: Todas as imagens foram construídas e enviadas com a tag '$tag'."
Write-Host "--------------------------------------------------"
