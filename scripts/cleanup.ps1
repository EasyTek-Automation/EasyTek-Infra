# cleanup.ps1
# Remove build cache e imagens Docker nao usadas ha mais de N dias.
# Seguro: so remove imagens sem container associado (ativo ou parado).
#
# Uso:
#   .\scripts\cleanup.ps1                    # janela default de 7 dias
#   .\scripts\cleanup.ps1 -days 30           # manter imagens dos ultimos 30 dias
#   .\scripts\cleanup.ps1 -days 0            # remover TODAS imagens sem uso (agressivo)

param (
    [int]$days = 7
)

if ($days -lt 0) {
    Write-Error "ERRO: -days nao pode ser negativo."
    exit 1
}

$hours = $days * 24

Write-Host "=== AMG Infra - Docker cleanup ==="
Write-Host "Janela de retencao: $days dias ($hours horas)"
Write-Host ""

Write-Host "--- Estado antes ---"
docker system df
Write-Host ""

Write-Host "--- Fase 1: limpando build cache ---"
docker builder prune -af
Write-Host ""

Write-Host "--- Fase 2: removendo imagens sem uso criadas ha mais de $days dias ---"
if ($days -eq 0) {
    docker image prune -af
} else {
    docker image prune -af --filter "until=${hours}h"
}
Write-Host ""

Write-Host "--- Estado depois ---"
docker system df
Write-Host ""
Write-Host "SUCESSO: Cleanup concluido."
