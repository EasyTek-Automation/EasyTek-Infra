# up.ps1
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [string]$env,

    [Parameter(Mandatory=$false)]
    [string]$tag = "latest"
)

# Define os caminhos para os arquivos de configuração
$envFile = ".\environments\$env\.env"
$overrideFile = ".\environments\$env\docker-compose.override.yml"
$githubUser = $env:GITHUB_USER # Pega o usuário do GH das variáveis de ambiente
$githubPat = $env:GITHUB_PAT   # Pega o PAT do GH das variáveis de ambiente

# --- Validação ---
Write-Host "INFO: Validando ambiente '$env'..."
if (-not (Test-Path $envFile)) {
    Write-Error "ERRO: Arquivo de ambiente '$envFile' não encontrado."
    exit 1
}
# ... (outras validações podem continuar aqui)

# --- Execução ---
try {
    # Passo 1: Autenticar no GHCR.IO nos ambientes remotos
    if ($env -ne 'local') {
        if (-not $githubUser -or -not $githubPat) {
            throw "ERRO: Para ambientes 'dev' ou 'prod', as variáveis de ambiente GITHUB_USER e GITHUB_PAT devem ser definidas."
        }
        Write-Host "INFO: Autenticando no ghcr.io..."
        $githubPat | docker login ghcr.io -u $githubUser --password-stdin
        if ($LASTEXITCODE -ne 0) {
            throw "Falha na autenticação com o ghcr.io."
        }
    }

    # Passo 2: Subir o proxy e a rede.
    Write-Host "INFO: Iniciando a infraestrutura de proxy para o ambiente '$env'..."
    docker compose --env-file $envFile -f proxy-compose.yml up -d --wait
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao iniciar o proxy-compose."
    }

    # Passo 3: Baixar as imagens mais recentes da aplicação
    Write-Host "INFO: Baixando (pull) as imagens da aplicação com a tag '$tag'..."
    # Define a tag para o compose usar
    $env:TAG = $tag
    docker compose --env-file $envFile -f docker-compose.yml -f $overrideFile pull
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao baixar as imagens do ghcr.io."
    }

    # Passo 4: Subir a aplicação principal (sem --build)
    Write-Host "INFO: Iniciando a aplicação principal para o ambiente '$env'..."
    docker compose --env-file $envFile -f docker-compose.yml -f $overrideFile up -d
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao iniciar o docker-compose principal."
    }

    Write-Host "SUCESSO: Ambiente '$env' iniciado com a tag '$tag'."

} catch {
    Write-Error "ERRO: Falha durante a inicialização do ambiente. $_"
    exit 1
}
