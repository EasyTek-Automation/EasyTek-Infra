# down.ps1 (Versão Profissional)
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'dev', 'prod')]
    [string]$env
)

$envFile = ".\environments\$env\.env"
$overrideFile = ".\environments\$env\docker-compose.override.yml"

Write-Host "INFO: Parando o ambiente '$env' de forma controlada..."

# Passo 1: Derrubar a aplicação principal.
# Ele usará os mesmos arquivos que o 'up.ps1' para saber exatamente o que parar.
docker compose --env-file $envFile -f "docker-compose.yml" -f $overrideFile down --remove-orphans

# Passo 2: Derrubar o proxy.
docker compose --env-file $envFile -f "proxy-compose.yml" down --remove-orphans

Write-Host "SUCESSO: Ambiente '$env' parado."
