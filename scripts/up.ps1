# up.ps1
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [string]$env,
    [string]$tag = "latest"
)

# --- Validação ---
$envFile = ".\environments\$env\.env"
$overrideFile = ".\environments\$env\docker-compose.override.yml"

Write-Host "INFO: Validando ambiente '$env'..."
if (-not (Test-Path $envFile)) {
    Write-Error "ERRO: Arquivo de ambiente '$envFile' não encontrado."
    exit 1
}
if ($env -ne 'local' -and (-not $env:GITHUB_USER -or -not $env:GITHUB_PAT)) {
    Write-Error "ERRO: Para ambientes 'dev' ou 'prod', as variáveis GITHUB_USER e GITHUB_PAT devem ser definidas."
    exit 1
}

# --- Execução ---
try {
    # Passo 1: Subir o proxy e a rede.
    Write-Host "INFO: Iniciando a infraestrutura de proxy para o ambiente '$env'..."
    docker compose --env-file $envFile -f "proxy-compose.yml" up -d --wait
    if ($LASTEXITCODE -ne 0) { throw "Falha ao iniciar o proxy-compose." }

    # Passo 2: Lógica diferente para local vs. remoto
    if ($env -eq 'local') {
        # PARA LOCAL: Usar o código-fonte local para construir as imagens
        Write-Host "INFO: Construindo e iniciando a aplicação principal para o ambiente local..."
        docker compose --env-file $envFile -f "docker-compose.yml" -f $overrideFile up -d --build
    }
    else {
        # PARA DEV/PROD: Baixar do registro
        Write-Host "INFO: Autenticando no ghcr.io..."
        $env:GITHUB_PAT | docker login ghcr.io -u $env:GITHUB_USER --password-stdin
        if ($LASTEXITCODE -ne 0) { throw "Falha na autenticação com o ghcr.io." }

        Write-Host "INFO: Baixando (pull) as imagens da aplicação com a tag '$tag'..."
        # Precisamos definir a variável TAG para que o compose a use
        $env:TAG = $tag
        docker compose --env-file $envFile -f "docker-compose.yml" -f $overrideFile pull
        if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar as imagens." }

        Write-Host "INFO: Iniciando a aplicação principal para o ambiente '$env'..."
        docker compose --env-file $envFile -f "docker-compose.yml" -f $overrideFile up -d
    }

    if ($LASTEXITCODE -ne 0) { throw "Falha ao iniciar o docker-compose principal." }

    Write-Host "SUCESSO: Ambiente '$env' iniciado com a tag '$tag'."

} catch {
    Write-Error "ERRO: Falha durante a inicialização do ambiente. $_"
    exit 1
}
