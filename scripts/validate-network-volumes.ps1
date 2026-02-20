# ==============================================================================
# Script de Validação de Volumes de Rede ZPP
# ==============================================================================
#
# Propósito: Validar que os volumes de rede estão funcionando corretamente
# Uso: .\validate-network-volumes.ps1
#
# ==============================================================================

$ErrorActionPreference = "Continue"

$NETWORK_BASE = "\\sumare\Comum\manutencao\AMG EASYTEK DATA"
$TESTS_PASSED = 0
$TESTS_FAILED = 0

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Validação de Volumes de Rede ZPP" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# Teste 1: Acesso à rede
# ==============================================================================
Write-Host "[1/8] Testando acesso à rede..." -ForegroundColor Yellow

if (Test-Path $NETWORK_BASE) {
    Write-Host "  [OK] Acesso ao compartilhamento" -ForegroundColor Green
    $TESTS_PASSED++
} else {
    Write-Host "  [X] Falha ao acessar $NETWORK_BASE" -ForegroundColor Red
    $TESTS_FAILED++
}

# ==============================================================================
# Teste 2: Diretórios existem
# ==============================================================================
Write-Host "[2/8] Verificando estrutura de diretórios..." -ForegroundColor Yellow

$directories = @("input", "output", "logs")
$dirTestPassed = $true

foreach ($dir in $directories) {
    $fullPath = Join-Path $NETWORK_BASE $dir

    if (Test-Path $fullPath) {
        Write-Host "  [OK] $dir existe" -ForegroundColor Green
    } else {
        Write-Host "  [X] $dir não encontrado" -ForegroundColor Red
        $dirTestPassed = $false
    }
}

if ($dirTestPassed) { $TESTS_PASSED++ } else { $TESTS_FAILED++ }

# ==============================================================================
# Teste 3: Permissões de escrita
# ==============================================================================
Write-Host "[3/8] Testando permissões de escrita..." -ForegroundColor Yellow

$testFile = Join-Path "$NETWORK_BASE\logs" "test-write-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

try {
    "Test write permission" | Out-File -FilePath $testFile -Force
    if (Test-Path $testFile) {
        Write-Host "  [OK] Escrita permitida" -ForegroundColor Green
        Remove-Item $testFile -Force
        $TESTS_PASSED++
    } else {
        Write-Host "  [X] Falha ao escrever arquivo" -ForegroundColor Red
        $TESTS_FAILED++
    }
} catch {
    Write-Host "  [X] Erro ao testar escrita: $_" -ForegroundColor Red
    $TESTS_FAILED++
}

# ==============================================================================
# Teste 4: Container está rodando
# ==============================================================================
Write-Host "[4/8] Verificando container ZPP Processor..." -ForegroundColor Yellow

$containerStatus = docker ps --filter "name=zpp-processor" --format "{{.Status}}"

if ($containerStatus -match "Up") {
    Write-Host "  [OK] Container rodando" -ForegroundColor Green
    $TESTS_PASSED++
} else {
    Write-Host "  [X] Container não está rodando" -ForegroundColor Red
    Write-Host "  Execute: docker-compose up -d zpp-processor" -ForegroundColor Yellow
    $TESTS_FAILED++
}

# ==============================================================================
# Teste 5: Volumes montados no container
# ==============================================================================
Write-Host "[5/8] Verificando volumes montados..." -ForegroundColor Yellow

$volumeMounts = @("/data/input", "/data/output", "/data/logs")
$volumeTestPassed = $true

foreach ($mount in $volumeMounts) {
    try {
        $result = docker exec zpp-processor test -d $mount 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] $mount montado" -ForegroundColor Green
        } else {
            Write-Host "  [X] $mount não montado" -ForegroundColor Red
            $volumeTestPassed = $false
        }
    } catch {
        Write-Host "  [X] Erro ao verificar $mount" -ForegroundColor Red
        $volumeTestPassed = $false
    }
}

if ($volumeTestPassed) { $TESTS_PASSED++ } else { $TESTS_FAILED++ }

# ==============================================================================
# Teste 6: API acessível
# ==============================================================================
Write-Host "[6/8] Testando API REST..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5002/api/health" -Method Get -TimeoutSec 5
    if ($response.status -eq "healthy") {
        Write-Host "  [OK] API respondendo" -ForegroundColor Green
        $TESTS_PASSED++
    } else {
        Write-Host "  [X] API retornou status: $($response.status)" -ForegroundColor Red
        $TESTS_FAILED++
    }
} catch {
    Write-Host "  [X] Erro ao acessar API: $_" -ForegroundColor Red
    $TESTS_FAILED++
}

# ==============================================================================
# Teste 7: Listar arquivos via API
# ==============================================================================
Write-Host "[7/8] Testando listagem de arquivos..." -ForegroundColor Yellow

try {
    $inputFiles = Invoke-RestMethod -Uri "http://localhost:5002/api/zpp/files/input" -Method Get -TimeoutSec 5
    $outputFiles = Invoke-RestMethod -Uri "http://localhost:5002/api/zpp/files/output" -Method Get -TimeoutSec 5

    Write-Host "  [OK] Arquivos pendentes: $($inputFiles.count)" -ForegroundColor Green
    Write-Host "  [OK] Arquivos processados: $($outputFiles.count)" -ForegroundColor Green
    $TESTS_PASSED++
} catch {
    Write-Host "  [X] Erro ao listar arquivos: $_" -ForegroundColor Red
    $TESTS_FAILED++
}

# ==============================================================================
# Teste 8: Sincronização rede <-> container
# ==============================================================================
Write-Host "[8/8] Testando sincronização rede/container..." -ForegroundColor Yellow

$syncTestFile = "sync-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$networkPath = Join-Path "$NETWORK_BASE\logs" $syncTestFile

try {
    # Criar arquivo na rede
    "Sync test from network" | Out-File -FilePath $networkPath -Force

    # Aguardar propagação
    Start-Sleep -Seconds 2

    # Verificar se aparece no container
    $containerCheck = docker exec zpp-processor test -f "/data/logs/$syncTestFile" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Sincronização funcionando" -ForegroundColor Green
        $TESTS_PASSED++
    } else {
        Write-Host "  [X] Arquivo não aparece no container" -ForegroundColor Red
        $TESTS_FAILED++
    }

    # Limpar
    Remove-Item $networkPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "  [X] Erro ao testar sincronização: $_" -ForegroundColor Red
    $TESTS_FAILED++
}

# ==============================================================================
# Resumo
# ==============================================================================
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Resumo da Validação" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = $TESTS_PASSED + $TESTS_FAILED
$successRate = [math]::Round(($TESTS_PASSED / $totalTests) * 100, 1)

Write-Host "Testes passados: $TESTS_PASSED/$totalTests ($successRate%)" -ForegroundColor $(if ($TESTS_FAILED -eq 0) { "Green" } else { "Yellow" })

if ($TESTS_FAILED -gt 0) {
    Write-Host "Testes falhados: $TESTS_FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ações recomendadas:" -ForegroundColor Yellow
    Write-Host "  1. Verificar .env.common (credenciais corretas)" -ForegroundColor White
    Write-Host "  2. Recriar container: docker-compose up -d zpp-processor" -ForegroundColor White
    Write-Host "  3. Verificar logs: docker logs zpp-processor" -ForegroundColor White
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "Configuração de volumes de rede está FUNCIONANDO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos passos:" -ForegroundColor Cyan
    Write-Host "  - Coloque arquivos .xlsx em: $NETWORK_BASE\input" -ForegroundColor White
    Write-Host "  - Acesse: http://localhost:8050/maintenance/zpp-processor" -ForegroundColor White
    Write-Host "  - Clique em 'Processar Agora'" -ForegroundColor White
    Write-Host ""
    exit 0
}
