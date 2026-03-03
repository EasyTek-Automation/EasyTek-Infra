# diagnose-docs-simple.ps1 - DiagnÃ³stico Simplificado

Write-Host ""
Write-Host "========================================"
Write-Host "DIAGNOSTICO - VOLUME DE DOCUMENTACAO"
Write-Host "========================================"
Write-Host ""

$docsPath = Join-Path (Split-Path -Parent $PSScriptRoot) "docs\procedures"

# 1. Verificar pasta no host
Write-Host "[1/6] Verificando pasta no servidor..." -ForegroundColor Yellow

if (Test-Path $docsPath) {
    Write-Host "  OK - Pasta existe: $docsPath" -ForegroundColor Green

    $mdFiles = Get-ChildItem -Path $docsPath -Filter *.md -Recurse -ErrorAction SilentlyContinue
    Write-Host "  OK - Arquivos .md encontrados: $($mdFiles.Count)" -ForegroundColor Green

    if ($mdFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "  Primeiros 5 arquivos:"
        $mdFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.Name)"
        }
    }
} else {
    Write-Host "  ERRO - Pasta nao existe!" -ForegroundColor Red
    Write-Host "  ACAO: Criar com 'mkdir $docsPath'" -ForegroundColor Yellow
}

Write-Host ""

# 2. Verificar containers
Write-Host "[2/6] Verificando containers..." -ForegroundColor Yellow

$containers = docker ps --format "table {{.Names}}" 2>$null | Select-Object -Skip 1

if ($containers) {
    Write-Host "  OK - Containers rodando:" -ForegroundColor Green
    $containers | ForEach-Object {
        Write-Host "    - $_"
    }

    $webappName = $containers | Where-Object { $_ -match "webapp" }
    if ($webappName) {
        Write-Host "  OK - Container webapp encontrado: $webappName" -ForegroundColor Green
        $script:webappContainer = $webappName
    } else {
        Write-Host "  AVISO - Container webapp nao encontrado" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERRO - Nenhum container rodando" -ForegroundColor Red
    Write-Host "  ACAO: Executar 'docker-compose up -d'" -ForegroundColor Yellow
}

Write-Host ""

# 3. Verificar volume no container
Write-Host "[3/6] Verificando volume no container..." -ForegroundColor Yellow

if ($script:webappContainer) {
    $volumeCheck = docker exec $script:webappContainer ls /app/docs/procedures 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK - Volume montado em /app/docs/procedures" -ForegroundColor Green

        $mdInContainer = docker exec $script:webappContainer sh -c "find /app/docs/procedures -name *.md -type f 2>/dev/null | wc -l"
        Write-Host "  OK - Arquivos .md no container: $mdInContainer" -ForegroundColor Green

        if ([int]$mdInContainer -eq 0) {
            Write-Host "  ERRO - Volume montado mas SEM arquivos!" -ForegroundColor Red
            Write-Host "  ACAO - Verificar mapeamento no docker-compose.yml" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ERRO - Pasta /app/docs/procedures NAO existe" -ForegroundColor Red
        Write-Host "  ACAO - Volume nao foi montado" -ForegroundColor Yellow
    }
} else {
    Write-Host "  AVISO - Container webapp nao esta rodando" -ForegroundColor Yellow
}

Write-Host ""

# 4. Verificar variavel de ambiente
Write-Host "[4/6] Verificando variavel de ambiente..." -ForegroundColor Yellow

if ($script:webappContainer) {
    $docsEnv = docker exec $script:webappContainer printenv DOCS_PROCEDURES_PATH 2>$null

    if ($docsEnv) {
        Write-Host "  OK - DOCS_PROCEDURES_PATH=$docsEnv" -ForegroundColor Green
    } else {
        Write-Host "  ERRO - DOCS_PROCEDURES_PATH nao definida!" -ForegroundColor Red
        Write-Host "  ACAO - Adicionar em docker-compose.yml" -ForegroundColor Yellow
    }
}

Write-Host ""

# 5. Verificar docker-compose.yml
Write-Host "[5/6] Verificando docker-compose.yml..." -ForegroundColor Yellow

$composeFile = Join-Path (Split-Path -Parent $PSScriptRoot) "docker-compose.yml"

if (Test-Path $composeFile) {
    $content = Get-Content $composeFile -Raw

    if ($content -match "volumes:" -and $content -match "docs/procedures") {
        Write-Host "  OK - Volume configurado" -ForegroundColor Green
    } else {
        Write-Host "  ERRO - Volume NAO configurado!" -ForegroundColor Red
    }

    if ($content -match "DOCS_PROCEDURES_PATH") {
        Write-Host "  OK - Variavel DOCS_PROCEDURES_PATH configurada" -ForegroundColor Green
    } else {
        Write-Host "  ERRO - Variavel NAO configurada!" -ForegroundColor Red
    }
} else {
    Write-Host "  ERRO - docker-compose.yml nao encontrado" -ForegroundColor Red
}

Write-Host ""

# 6. Verificar logs
Write-Host "[6/6] Verificando logs do webapp..." -ForegroundColor Yellow

if ($script:webappContainer) {
    $logsWithDocs = docker logs $script:webappContainer --tail 50 2>&1 | Select-String -Pattern "docs|procedures" -Quiet

    if ($logsWithDocs) {
        Write-Host "  OK - Mencoes a 'docs' encontradas nos logs" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Logs relevantes:"
        docker logs $script:webappContainer --tail 50 2>&1 | Select-String -Pattern "docs|procedures" | ForEach-Object {
            Write-Host "    $_"
        }
    } else {
        Write-Host "  AVISO - Nenhuma mencao a docs nos logs" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "PROXIMOS PASSOS"
Write-Host "========================================"
Write-Host ""

Write-Host "Se tudo estiver OK mas nao aparecer:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Reiniciar container:"
Write-Host "     docker-compose restart webapp"
Write-Host ""
Write-Host "  2. Ver logs ao vivo:"
Write-Host "     docker logs -f $script:webappContainer"
Write-Host ""
Write-Host "  3. Testar dentro do container:"
Write-Host "     docker exec -it $script:webappContainer bash"
Write-Host "     ls -la /app/docs/procedures/"
Write-Host ""

Write-Host "Diagnostico concluido!" -ForegroundColor Green
Write-Host ""


