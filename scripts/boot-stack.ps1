# boot-stack.ps1
# Sobe a stack de containers apos o logon.
#
# Motivo de existir: o Docker Desktop inicia junto com o logon, mas os volumes
# CIFS (//$FileServerHost) sao montados no START do container. Se a rede corporativa
# ainda nao respondeu, o mount falha -- e falha de mount e falha de START, que
# a politica restart:unless-stopped NAO cobre. Resultado: webapp e zpp-processor
# ficam parados. Este script espera as dependencias e reconcilia o estado.
#
# NAO faz pull nem login no ghcr.io: usa as imagens que ja estao na maquina.
# Boot nao e deploy. Para atualizar versao, use scripts/up.ps1.
# NAO toca no daemon sap-scheduler: ele ja tem gatilho proprio de logon.

param(
    [ValidateSet('local','dev','prod')]
    [string]$environment = 'prod',
    [int]$DockerTimeoutSec = 300,
    [int]$ShareTimeoutSec  = 180,
    [string]$FileServerHost = 'file-server'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$logDir = Join-Path $root 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$log = Join-Path $logDir 'boot-stack.log'

function Write-Log {
    param([string]$msg, [string]$level = 'INFO')
    $line = "[{0}] {1,-5} {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $level, $msg
    Add-Content -Path $log -Value $line -Encoding utf8
    Write-Host $line
}

# Executa o docker capturando saida com seguranca.
# No Windows PowerShell 5.1, "nativo.exe 2>&1 |" embrulha cada linha de stderr
# num ErrorRecord; com ErrorActionPreference='Stop' um simples WARNING do docker
# viraria erro terminante e derrubaria o boot. Por isso baixamos para 'Continue'
# ao redor da chamada nativa e decidimos sucesso/falha pelo exit code.
function Invoke-Docker {
    param([string[]]$DockerArgs, [string]$What)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out  = & docker @DockerArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    foreach ($line in $out) {
        $t = $line.ToString().Trim()
        if ($t) { Write-Log "  $t" }
    }
    if ($code -ne 0) { throw "$What (exit=$code)" }
}

# Mantem o log em tamanho sano (~1 MB) entre reboots.
if ((Test-Path $log) -and ((Get-Item $log).Length -gt 1MB)) {
    Move-Item $log "$log.old" -Force
}

Write-Log "===== boot-stack iniciado (ambiente=$environment, usuario=$env:USERNAME) ====="

$envFile      = ".\environments\$environment\.env"
$overrideFile = ".\environments\$environment\docker-compose.override.yml"
$projectName  = if ($environment -eq 'dev') { 'easytek-infra-dev' } else { 'easytek-infra' }

if (-not (Test-Path $envFile)) {
    Write-Log "Arquivo de ambiente '$envFile' nao encontrado. Abortando." 'ERRO'
    exit 1
}

# --- 1. Esperar o daemon do Docker responder ---
Write-Log "Aguardando o daemon do Docker (timeout ${DockerTimeoutSec}s)..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$dockerOk = $false
while ($sw.Elapsed.TotalSeconds -lt $DockerTimeoutSec) {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $dockerOk = $true; break }
    Start-Sleep -Seconds 5
}
if (-not $dockerOk) {
    Write-Log "Docker nao respondeu em ${DockerTimeoutSec}s. O Docker Desktop iniciou?" 'ERRO'
    exit 1
}
Write-Log ("Docker respondeu apos {0:N0}s." -f $sw.Elapsed.TotalSeconds)

# --- 2. Esperar o file server CIFS (porta 445) ---
# Sem isso os mounts de //$FileServerHost falham e os containers nao iniciam.
Write-Log "Aguardando o file server //$FileServerHost na porta 445 (timeout ${ShareTimeoutSec}s)..."
$sw2 = [Diagnostics.Stopwatch]::StartNew()
$shareOk = $false
while ($sw2.Elapsed.TotalSeconds -lt $ShareTimeoutSec) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect($FileServerHost, 445)
        $shareOk = $c.Connected
        $c.Close()
        if ($shareOk) { break }
    } catch { }
    Start-Sleep -Seconds 5
}
if ($shareOk) {
    Write-Log ("File server respondeu apos {0:N0}s." -f $sw2.Elapsed.TotalSeconds)
} else {
    # Segue mesmo assim: os servicos sem CIFS (mongo, gateway, mobile, node-red)
    # ainda sobem, e o log deixa claro o motivo se webapp/zpp ficarem fora.
    Write-Log "File server //$FileServerHost nao respondeu em ${ShareTimeoutSec}s. Seguindo; mounts CIFS podem falhar." 'AVISO'
}

# --- 3. Subir proxy e aplicacao (sem pull) ---
try {
    $proxyEnvFile = if ($environment -eq 'dev') { ".\environments\prod\.env" } else { $envFile }

    # O proxy roda sob o MESMO project name da aplicacao ('easytek-infra') e seu
    # compose declara apenas o nginx. Rodar 'up -d' so com proxy-compose.yml faz
    # o Compose tratar webapp/database/etc. como fora do projeto e PARA-LOS por
    # alguns segundos (observado em teste: 6 containers reiniciados). No boot isso
    # seria inofensivo, mas este script tambem pode ser rodado com a stack viva.
    # Por isso o passo so acontece quando ele e realmente necessario.
    #
    # NUNCA use --remove-orphans aqui: sob o project name compartilhado, a flag
    # APAGARIA os containers da aplicacao.
    $redeOk  = @(docker network ls --filter name=^easytek-net$ --format '{{.Name}}') -contains 'easytek-net'
    $proxyOk = @(docker ps --filter name=^nginx-proxy-manager$ --filter status=running --format '{{.Names}}') -contains 'nginx-proxy-manager'

    if ($redeOk -and $proxyOk) {
        Write-Log "Proxy ja no ar e rede 'easytek-net' existe -- passo do proxy dispensado."
    } else {
        Write-Log "Subindo o proxy (rede=$redeOk proxy=$proxyOk)..."
        Invoke-Docker -What "falha ao subir o proxy-compose" -DockerArgs @(
            'compose','--project-name','easytek-infra','--env-file',$proxyEnvFile,
            '-f','proxy-compose.yml','up','-d')
    }

    Write-Log "Subindo a aplicacao principal (projeto=$projectName)..."
    Invoke-Docker -What "falha ao subir o docker-compose principal" -DockerArgs @(
        'compose','--project-name',$projectName,'--env-file',$envFile,
        '-f','docker-compose.yml','-f',$overrideFile,'up','-d')

} catch {
    Write-Log "Falha ao reconciliar a stack: $_" 'ERRO'
    exit 1
}

# --- 4. Conferir o resultado ---
# mongo-init e um job one-shot: sair com codigo 0 e o esperado, nao e falha.
$parados = @()
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$psOut = & docker compose --project-name $projectName --env-file $envFile -f "docker-compose.yml" -f $overrideFile ps -a --format '{{.Service}}|{{.State}}|{{.ExitCode}}' 2>$null
$ErrorActionPreference = $prev
$psOut | ForEach-Object {
        $p = $_ -split '\|'
        if ($p.Count -ge 2) {
            $svc, $state = $p[0], $p[1]
            $code = if ($p.Count -ge 3) { $p[2] } else { '' }
            if ($state -eq 'running') {
                Write-Log "  OK      $svc"
            } elseif ($svc -eq 'mongo-init' -and $code -eq '0') {
                Write-Log "  OK      $svc (job one-shot concluido)"
            } else {
                Write-Log "  PARADO  $svc (state=$state exit=$code)" 'AVISO'
                $parados += $svc
            }
        }
    }

if ($parados.Count -gt 0) {
    Write-Log ("Servicos fora do ar: {0}" -f ($parados -join ', ')) 'ERRO'
    Write-Log "===== boot-stack terminou COM PENDENCIAS ====="
    exit 1
}

Write-Log "===== boot-stack terminou OK: stack completa no ar ====="
exit 0
