# up.ps1
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [Alias('env')]
    [string]$environment,
    [string]$tag = "latest",
    # Pula o deploy do daemon nativo sap-scheduler (só containers). Útil em local
    # ou quando o daemon não deve ser tocado.
    [switch]$SkipDaemon
)

# --- Validação ---
$envFile = ".\environments\${environment}\.env"
$overrideFile = ".\environments\${environment}\docker-compose.override.yml"
Write-Host "DEBUG: Usando env-file em '$envFile'"

Write-Host "INFO: Validando ambiente '$environment'..."
if (-not (Test-Path $envFile)) {
    Write-Error "ERRO: Arquivo de ambiente '$envFile' não encontrado."
    exit 1
}

# Carregar credenciais do GitHub a partir do .env raiz (se existir)
$rootEnvFile = ".\.env"
if (Test-Path $rootEnvFile) {
    Get-Content $rootEnvFile | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
        $parts = $_ -split '=', 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim().Trim('"').Trim("'")
            Set-Item -Path "env:$key" -Value $value
        }
    }
}

if ($environment -ne 'local' -and (-not $env:GITHUB_USER -or -not $env:GITHUB_PAT)) {
    Write-Error "ERRO: Para ambientes 'dev' ou 'prod', defina GITHUB_USER e GITHUB_PAT no arquivo .env da raiz."
    exit 1
}
$env:TAG = $tag

# Nome do projeto Docker Compose: dev usa nome separado para coexistir com prod
$projectName = if ($environment -eq 'dev') { 'amg-infra-dev' } else { 'amg-infra' }

# --- Execução ---
try {
    # Passo 1: Subir o proxy e a rede (sempre com projeto fixo, pois o nginx é compartilhado)
    # Dev usa o env do prod para o proxy, já que o nginx é gerenciado pelo prod
    $proxyEnvFile = if ($environment -eq 'dev') { ".\environments\prod\.env" } else { $envFile }
    Write-Host "INFO: Iniciando a infraestrutura de proxy para o ambiente '$environment'..."
    docker compose --project-name amg-infra --env-file $proxyEnvFile -f "proxy-compose.yml" up -d --wait
    if ($LASTEXITCODE -ne 0) { throw "Falha ao iniciar o proxy-compose." }

    # Passo 2: Lógica diferente para local vs. remoto
    if ($environment -eq 'local') {
        # PARA LOCAL: Usar o código-fonte local para construir as imagens
        Write-Host "INFO: Construindo e iniciando a aplicação principal para o ambiente local..."
        docker compose --project-name $projectName --env-file $envFile -f "docker-compose.yml" -f $overrideFile up -d --build
    }
    else {
        # PARA DEV/PROD: Baixar do registro
        Write-Host "INFO: Autenticando no ghcr.io..."
        $env:GITHUB_PAT | docker login ghcr.io -u $env:GITHUB_USER --password-stdin
        if ($LASTEXITCODE -ne 0) { throw "Falha na autenticação com o ghcr.io." }

        Write-Host "INFO: Baixando (pull) as imagens da aplicação com a tag '$tag'..."
        $env:TAG = $tag
        docker compose --project-name $projectName --env-file $envFile -f "docker-compose.yml" -f $overrideFile pull
        if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar as imagens." }

        Write-Host "INFO: Iniciando a aplicação principal para o ambiente '$environment'..."
        docker compose --project-name $projectName --env-file $envFile -f "docker-compose.yml" -f $overrideFile up -d
    }

    if ($LASTEXITCODE -ne 0) { throw "Falha ao iniciar o docker-compose principal." }

    # Passo 3: Deploy do daemon nativo sap-scheduler (não containeriza — SAP GUI).
    # Só em dev/prod (no servidor) e com tag explícita. Falha aqui NÃO derruba os
    # containers já no ar — o daemon é independente; reporta e segue.
    if ($environment -ne 'local' -and -not $SkipDaemon -and $tag -ne 'latest') {
        Write-Host "INFO: Atualizando o daemon sap-scheduler para a tag '$tag'..."
        try {
            & (Join-Path $PSScriptRoot 'deploy-daemon.ps1') -tag $tag
        } catch {
            Write-Warning "Containers no ar, mas o deploy do daemon sap-scheduler falhou: $_"
            Write-Warning "Rode manualmente: .\scripts\deploy-daemon.ps1 -tag $tag"
        }
    } elseif ($environment -ne 'local' -and $tag -eq 'latest') {
        Write-Warning "Daemon sap-scheduler não atualizado: informe uma tag explícita (ex: .\up.ps1 prod 20260615.1430)."
    }

    Write-Host "SUCESSO: Ambiente '$environment' iniciado com a tag '$tag'."

} catch {
    Write-Error "ERRO: Falha durante a inicialização do ambiente. $_"
    exit 1
}
