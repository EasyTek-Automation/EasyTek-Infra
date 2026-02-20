# ==============================================================================
# Script de Migração ZPP para Volumes de Rede
# ==============================================================================
#
# Propósito: Preparar estrutura de diretórios na rede e migrar dados existentes
# Caminho de rede: \\sumare\Comum\manutencao\AMG EASYTEK DATA
#
# Uso:
#   .\migrate-zpp-to-network.ps1
#
# ==============================================================================

$ErrorActionPreference = "Stop"

# Configuração
$NETWORK_BASE = "\\sumare\Comum\manutencao\AMG EASYTEK DATA"
$LOCAL_BASE = "..\volumes\zpp"

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Migração ZPP para Volumes de Rede" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Etapa 1: Validar acesso à rede
# ============================================================================
Write-Host "[1/5] Validando acesso à rede..." -ForegroundColor Yellow

if (-not (Test-Path $NETWORK_BASE)) {
    Write-Host "ERRO: Não foi possível acessar $NETWORK_BASE" -ForegroundColor Red
    Write-Host "Verifique:" -ForegroundColor Yellow
    Write-Host "  - Se o compartilhamento está disponível" -ForegroundColor Yellow
    Write-Host "  - Se você tem permissão de acesso" -ForegroundColor Yellow
    Write-Host "  - Se o servidor 'sumare' está online" -ForegroundColor Yellow
    exit 1
}

Write-Host "  [OK] Acesso à rede validado" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Etapa 2: Criar estrutura de diretórios na rede
# ============================================================================
Write-Host "[2/5] Criando estrutura de diretórios..." -ForegroundColor Yellow

$directories = @("input", "output", "logs")

foreach ($dir in $directories) {
    $fullPath = Join-Path $NETWORK_BASE $dir

    if (Test-Path $fullPath) {
        Write-Host "  [OK] $dir já existe" -ForegroundColor Gray
    } else {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  [OK] $dir criado" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================================================
# Etapa 3: Verificar arquivos locais
# ============================================================================
Write-Host "[3/5] Verificando arquivos locais..." -ForegroundColor Yellow

$inputFiles = Get-ChildItem -Path "$LOCAL_BASE\input\*.xlsx" -ErrorAction SilentlyContinue
$outputFiles = Get-ChildItem -Path "$LOCAL_BASE\output\*.xlsx" -ErrorAction SilentlyContinue

Write-Host "  Arquivos pendentes (input):   $($inputFiles.Count)" -ForegroundColor Cyan
Write-Host "  Arquivos processados (output): $($outputFiles.Count)" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Etapa 4: Migrar arquivos
# ============================================================================
Write-Host "[4/5] Migrando arquivos para a rede..." -ForegroundColor Yellow

# Migrar INPUT (planilhas pendentes)
if ($inputFiles.Count -gt 0) {
    Write-Host "  Migrando INPUT..." -ForegroundColor Cyan

    foreach ($file in $inputFiles) {
        $destination = Join-Path "$NETWORK_BASE\input" $file.Name

        if (Test-Path $destination) {
            Write-Host "    [!] $($file.Name) já existe, pulando..." -ForegroundColor Yellow
        } else {
            Copy-Item -Path $file.FullName -Destination $destination -Force
            Write-Host "    [OK] $($file.Name)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  [OK] Nenhum arquivo pendente para migrar" -ForegroundColor Gray
}

Write-Host ""

# Migrar OUTPUT (planilhas processadas)
if ($outputFiles.Count -gt 0) {
    Write-Host "  Migrando OUTPUT..." -ForegroundColor Cyan

    $copiedCount = 0
    $skippedCount = 0

    foreach ($file in $outputFiles) {
        $destination = Join-Path "$NETWORK_BASE\output" $file.Name

        if (Test-Path $destination) {
            $skippedCount++
        } else {
            Copy-Item -Path $file.FullName -Destination $destination -Force
            $copiedCount++
        }
    }

    Write-Host "    [OK] $copiedCount arquivo(s) copiado(s)" -ForegroundColor Green
    if ($skippedCount -gt 0) {
        Write-Host "    [!] $skippedCount arquivo(s) já existiam" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] Nenhum arquivo processado para migrar" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Etapa 5: Validar migração
# ============================================================================
Write-Host "[5/5] Validando migração..." -ForegroundColor Yellow

$networkInputFiles = Get-ChildItem -Path "$NETWORK_BASE\input\*.xlsx" -ErrorAction SilentlyContinue
$networkOutputFiles = Get-ChildItem -Path "$NETWORK_BASE\output\*.xlsx" -ErrorAction SilentlyContinue

Write-Host "  Arquivos na rede (input):  $($networkInputFiles.Count)" -ForegroundColor Cyan
Write-Host "  Arquivos na rede (output): $($networkOutputFiles.Count)" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Resumo
# ============================================================================
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Migração Concluída!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Edite .env.common e configure:" -ForegroundColor White
Write-Host "     ZPP_NETWORK_USER=seu_usuario_windows" -ForegroundColor Gray
Write-Host "     ZPP_NETWORK_PASSWORD=sua_senha" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Recriar o container ZPP Processor:" -ForegroundColor White
Write-Host "     docker-compose down" -ForegroundColor Gray
Write-Host "     docker-compose up -d zpp-processor" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Validar montagem dos volumes:" -ForegroundColor White
Write-Host "     docker exec zpp-processor ls -la /data/input" -ForegroundColor Gray
Write-Host "     docker exec zpp-processor ls -la /data/output" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Testar processamento via interface web:" -ForegroundColor White
Write-Host "     http://localhost:8050/maintenance/zpp-processor" -ForegroundColor Gray
Write-Host ""
