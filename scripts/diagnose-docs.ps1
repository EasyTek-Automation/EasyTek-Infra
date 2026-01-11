# diagnose-docs.ps1 - Diagnóstico do Volume de Documentação
# Execute este script no servidor Windows via AnyDesk

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNÓSTICO - VOLUME DE DOCUMENTAÇÃO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$docsPath = "C:\AMG-Infra\docs\procedures"

# ========================================
# 1. Verificar se pasta existe no host
# ========================================
Write-Host "[1/6] Verificando pasta no servidor..." -ForegroundColor Yellow

if (Test-Path $docsPath) {
    Write-Host "  ✓ Pasta existe: $docsPath" -ForegroundColor Green

    # Contar arquivos .md
    $mdFiles = Get-ChildItem -Path $docsPath -Filter "*.md" -Recurse
    Write-Host "  ✓ Arquivos .md encontrados: $($mdFiles.Count)" -ForegroundColor Green

    if ($mdFiles.Count -gt 0) {
        Write-Host "`n  Primeiros 5 arquivos:" -ForegroundColor Gray
        $mdFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.FullName)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ✗ ERRO: Pasta não existe!" -ForegroundColor Red
    Write-Host "  → Criar pasta: mkdir '$docsPath'" -ForegroundColor Yellow
}

# ========================================
# 2. Verificar containers rodando
# ========================================
Write-Host "`n[2/6] Verificando containers..." -ForegroundColor Yellow

$containers = docker ps --format "{{.Names}}" 2>$null

if ($containers) {
    Write-Host "  ✓ Containers rodando:" -ForegroundColor Green
    $containers | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor Gray
    }

    # Verificar se webapp está rodando
    $webappRunning = $containers -match "webapp"
    if ($webappRunning) {
        Write-Host "  ✓ Webapp está rodando" -ForegroundColor Green
    } else {
        Write-Host "  ✗ AVISO: Container 'webapp' não encontrado" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ ERRO: Nenhum container rodando" -ForegroundColor Red
    Write-Host "  → Iniciar: docker-compose up -d" -ForegroundColor Yellow
}

# ========================================
# 3. Verificar volume montado no container
# ========================================
Write-Host "`n[3/6] Verificando volume no container..." -ForegroundColor Yellow

$webappContainer = docker ps --filter "name=webapp" --format "{{.Names}}" 2>$null

if ($webappContainer) {
    # Verificar se pasta existe dentro do container
    $result = docker exec $webappContainer ls -la /app/docs/procedures 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Volume montado em /app/docs/procedures" -ForegroundColor Green

        # Contar arquivos .md dentro do container
        $mdCount = docker exec $webappContainer find /app/docs/procedures -name "*.md" -type f 2>$null | Measure-Object -Line
        Write-Host "  ✓ Arquivos .md no container: $($mdCount.Lines)" -ForegroundColor Green

        if ($mdCount.Lines -eq 0) {
            Write-Host "  ✗ ERRO: Volume montado mas SEM arquivos!" -ForegroundColor Red
            Write-Host "  → Verificar mapeamento em docker-compose.yml" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ ERRO: Pasta /app/docs/procedures NÃO existe no container" -ForegroundColor Red
        Write-Host "  → Volume não foi montado corretamente" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ AVISO: Container webapp não está rodando" -ForegroundColor Yellow
}

# ========================================
# 4. Verificar variável de ambiente
# ========================================
Write-Host "`n[4/6] Verificando variável de ambiente..." -ForegroundColor Yellow

if ($webappContainer) {
    $docsEnv = docker exec $webappContainer env 2>$null | Select-String "DOCS_PROCEDURES_PATH"

    if ($docsEnv) {
        Write-Host "  ✓ Variável configurada: $docsEnv" -ForegroundColor Green
    } else {
        Write-Host "  ✗ ERRO: DOCS_PROCEDURES_PATH não está definida!" -ForegroundColor Red
        Write-Host "  → Adicionar em docker-compose.yml:" -ForegroundColor Yellow
        Write-Host "    environment:" -ForegroundColor Gray
        Write-Host "      - DOCS_PROCEDURES_PATH=/app/docs/procedures" -ForegroundColor Gray
    }
}

# ========================================
# 5. Verificar docker-compose.yml
# ========================================
Write-Host "`n[5/6] Verificando docker-compose.yml..." -ForegroundColor Yellow

$composeFile = "C:\AMG-Infra\docker-compose.yml"

if (Test-Path $composeFile) {
    $composeContent = Get-Content $composeFile -Raw

    # Verificar se tem volume configurado
    if ($composeContent -match "volumes:" -and $composeContent -match "docs/procedures") {
        Write-Host "  ✓ Volume configurado em docker-compose.yml" -ForegroundColor Green
    } else {
        Write-Host "  ✗ ERRO: Volume NÃO configurado!" -ForegroundColor Red
        Write-Host "  → Adicionar no serviço webapp:" -ForegroundColor Yellow
        Write-Host "    volumes:" -ForegroundColor Gray
        Write-Host "      - ./docs/procedures:/app/docs/procedures:ro" -ForegroundColor Gray
    }

    # Verificar variável de ambiente
    if ($composeContent -match "DOCS_PROCEDURES_PATH") {
        Write-Host "  ✓ Variável DOCS_PROCEDURES_PATH configurada" -ForegroundColor Green
    } else {
        Write-Host "  ✗ ERRO: Variável DOCS_PROCEDURES_PATH NÃO configurada!" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ ERRO: docker-compose.yml não encontrado em $composeFile" -ForegroundColor Red
}

# ========================================
# 6. Verificar logs do webapp
# ========================================
Write-Host "`n[6/6] Verificando logs do webapp..." -ForegroundColor Yellow

if ($webappContainer) {
    $logs = docker logs $webappContainer --tail 50 2>$null | Select-String -Pattern "docs|procedures|DOCS_PROCEDURES" -Context 0,1

    if ($logs) {
        Write-Host "  ✓ Logs relacionados a docs:" -ForegroundColor Green
        $logs | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠ Nenhuma menção a 'docs' nos logs recentes" -ForegroundColor Yellow
        Write-Host "`n  Últimas 10 linhas do log:" -ForegroundColor Gray
        docker logs $webappContainer --tail 10 2>$null | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
}

# ========================================
# RESUMO E RECOMENDAÇÕES
# ========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESUMO E PRÓXIMOS PASSOS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Se TODOS os checks acima estiverem OK mas ainda não aparecer:" -ForegroundColor Yellow
Write-Host "  1. Reiniciar container:" -ForegroundColor White
Write-Host "     docker-compose restart webapp`n" -ForegroundColor Gray

Write-Host "  2. Verificar se página de procedimentos existe:" -ForegroundColor White
Write-Host "     Acessar: http://localhost:8050/maintenance/procedures`n" -ForegroundColor Gray

Write-Host "  3. Ver logs completos:" -ForegroundColor White
Write-Host "     docker logs -f <nome-container> | Select-String docs`n" -ForegroundColor Gray

Write-Host "  4. Testar dentro do container:" -ForegroundColor White
Write-Host "     docker exec -it <nome-container> bash" -ForegroundColor Gray
Write-Host "     ls -la /app/docs/procedures/" -ForegroundColor Gray
Write-Host "     cat /app/docs/procedures/index.md`n" -ForegroundColor Gray

Write-Host "`nDiagnóstico concluído!`n" -ForegroundColor Green
