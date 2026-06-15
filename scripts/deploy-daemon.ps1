# deploy-daemon.ps1 — atualiza o daemon sap-scheduler no servidor (Windows nativo).
#
# O daemon NÃO containeriza (SAP GUI, Python 32-bit). Em vez de imagem, ele é
# baixado como artefato .zip do GitHub Release (mesma tag das imagens) e roda
# nativo. Este script: baixa o zip da tag -> extrai preservando .env/.venv/logs
# -> atualiza a venv -> reinicia a tarefa agendada "SAP Job Scheduler".
#
# Chamado automaticamente por up.ps1 (dev/prod) ou manualmente:
#   .\scripts\deploy-daemon.ps1 -tag 20260615.1430
#
# Idempotente e reversível: rodar com uma tag anterior restaura aquela versão
# (o .env nunca é tocado; a carga de custo é idempotente). Ver
# AMG_Data/sap-scheduler/RECUPERACAO.md.

param (
    [Parameter(Mandatory = $true)]
    [string]$tag,

    # Onde o daemon vive no servidor. Default = onde ele já roda hoje.
    [string]$DestDir = (Join-Path $env:USERPROFILE 'sap-scheduler'),

    # Repo que hospeda o Release (origin de deploy do AMG_Data).
    [string]$Repo = $(if ($env:DAEMON_RELEASE_REPO) { $env:DAEMON_RELEASE_REPO } else { 'EasyTek-Automation/AMG-Data' }),

    # Nome da tarefa agendada do Windows.
    [string]$TaskName = 'SAP Job Scheduler'
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "INFO (daemon): $msg" }

# --- Credencial: reusa GITHUB_PAT do .env raiz (mesmo do docker login ghcr) ---
$pat = $env:GITHUB_PAT
if (-not $pat) {
    $rootEnv = Join-Path $PSScriptRoot '..\.env'
    if (Test-Path $rootEnv) {
        Get-Content $rootEnv | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                $k = $parts[0].Trim()
                $v = $parts[1].Trim().Trim('"').Trim("'")
                if ($k -eq 'GITHUB_PAT') { $pat = $v }
            }
        }
    }
}
if (-not $pat) { throw "GITHUB_PAT não encontrado (env nem .env raiz). Necessário pra baixar o Release de repo privado." }

$asset = "sap-scheduler-$tag.zip"
$headers = @{
    Authorization = "token $pat"
    'User-Agent'  = 'amg-deploy-daemon'
    Accept        = 'application/vnd.github+json'
}

# --- 1. Resolver o asset do Release pela tag ---
Write-Step "Resolvendo Release '$tag' em $Repo ..."
try {
    $rel = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Repo/releases/tags/$tag"
} catch {
    throw "Release da tag '$tag' não encontrado em $Repo. O workflow build-and-push concluiu? ($_)"
}
$assetObj = $rel.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1
if (-not $assetObj) { throw "Asset '$asset' não está no Release '$tag'. Assets: $($rel.assets.name -join ', ')" }

# --- 2. Baixar o zip (Accept octet-stream no endpoint do asset) ---
$staging = Join-Path $env:TEMP "sap-scheduler-deploy-$tag"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null
$zipPath = Join-Path $staging $asset

Write-Step "Baixando $asset ..."
$dlHeaders = @{ Authorization = "token $pat"; 'User-Agent' = 'amg-deploy-daemon'; Accept = 'application/octet-stream' }
Invoke-WebRequest -Headers $dlHeaders -Uri $assetObj.url -OutFile $zipPath

# --- 3. Extrair pro staging ---
Write-Step "Extraindo ..."
$extract = Join-Path $staging 'extract'
Expand-Archive -Path $zipPath -DestinationPath $extract -Force
$srcDir = Join-Path $extract 'sap-scheduler'   # zip tem prefixo sap-scheduler/
if (-not (Test-Path $srcDir)) { throw "Estrutura inesperada no zip: $srcDir ausente." }

# --- 4. Sincronizar pro destino preservando estado local (.env/.venv/logs/old) ---
# robocopy /MIR espelha o CÓDIGO mas /XD e /XF protegem o que é local do servidor.
if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir | Out-Null }
Write-Step "Sincronizando código pra $DestDir (preserva .env, .venv, logs) ..."
robocopy $srcDir $DestDir /MIR /XD '.venv' 'logs' 'old' /XF '.env' 'daemon.lock' /NJH /NJS /NDL /NP | Out-Null
# robocopy: exit 0-7 = sucesso; >=8 = erro real
if ($LASTEXITCODE -ge 8) { throw "robocopy falhou (exit $LASTEXITCODE) ao sincronizar o daemon." }
$global:LASTEXITCODE = 0

# --- 5. Garantir/atualizar a venv (Python 32-bit) ---
$venvPy = Join-Path $DestDir '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPy)) {
    Write-Step "venv ausente — criando (Python 32-bit) ..."
    & py -3-32 -m venv (Join-Path $DestDir '.venv')
    if ($LASTEXITCODE -ne 0) { throw "Falha ao criar a venv 32-bit. Python 32-bit instalado? (py -3-32)" }
}
Write-Step "Atualizando dependências ..."
& $venvPy -m pip install --quiet --upgrade pip
& $venvPy -m pip install --quiet -r (Join-Path $DestDir 'setup\requirements.txt')
if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar requirements na venv." }

# --- 6. Reiniciar a tarefa agendada (carrega código novo) ---
Write-Step "Reiniciando a tarefa '$TaskName' ..."
try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue } catch {}
$lock = Join-Path $DestDir 'daemon.lock'
if (Test-Path $lock) {
    $oldPid = (Get-Content $lock -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($oldPid) { try { Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue } catch {} }
    Remove-Item $lock -Force -ErrorAction SilentlyContinue
}
Start-ScheduledTask -TaskName $TaskName

Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
Write-Step "Daemon atualizado para a tag '$tag'. Acompanhe: Get-Content '$DestDir\logs\daemon.log' -Wait -Tail 10"
