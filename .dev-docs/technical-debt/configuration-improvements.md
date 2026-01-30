# 🔧 Melhorias - Configuração

Detalhamento técnico das melhorias de configuração identificadas.

---

## 🔴 Alta Prioridade

### 1. Criar .env.example Adequado {#1-env-example}

**Problema Atual**

Arquivos `.env.example` existentes estão incompletos:

**`environments/local/.env.example`** (apenas 5 variáveis):
```env
PORTAINER_DATA_PATH=
NGINX_DATA_PATH=
NGINX_LETSENCRYPT_PATH=
NODE_RED_DATA_PATH=
CODE_PATH=
```

**Faltam 12+ variáveis obrigatórias**:
- MONGO_URI
- DB_NAME
- MQTT_BROKER_ADDRESS
- MQTT_BROKER_PORT
- MQTT_USERNAME
- MQTT_PASSWORD
- SECRET_KEY
- GATEWAY_URL
- DOCS_PROCEDURES_PATH
- GITHUB_USER (dev/prod)
- GITHUB_PAT (dev/prod)
- TAG

**Consequências**:
- ❌ Novo dev copia `.env.example`, faltam variáveis → app não inicia
- ❌ Mensagens de erro crípticas ("KeyError: 'MONGO_URI'")
- ❌ Desenvolvedor não sabe quais valores preencher

**Solução Proposta**

Criar `.env.example` completo na raiz:

```env
# .env.example - Template de configuração
# Copie para .env e preencha com valores reais

# GitHub Container Registry (obrigatório para dev/prod)
# Gerar em: https://github.com/settings/tokens
GITHUB_USER=seu_usuario_github
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# MongoDB (obrigatório)
# Exemplo Local: mongodb://host.docker.internal:27017
# Exemplo Cloud: mongodb+srv://usuario:senha@cluster.mongodb.net/database
MONGO_URI=mongodb+srv://usuario:senha@cluster.mongodb.net/?retryWrites=true&w=majority
DB_NAME=nome_do_banco

# MQTT Broker (obrigatório)
# HiveMQ Cloud ou outro broker
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario_mqtt
MQTT_PASSWORD=sua_senha_mqtt

# Application Secret (obrigatório)
# Gerar com: python -c 'import secrets; print(secrets.token_hex(32))'
SECRET_KEY=sua_chave_secreta_64_caracteres_hexadecimais

# Event Gateway (obrigatório)
# Local: http://localhost:5001
# Docker: http://event-gateway:5001
GATEWAY_URL=http://event-gateway:5001

# Documentação (obrigatório para webapp)
DOCS_PROCEDURES_PATH=/app/docs/procedures

# Tag da imagem Docker (opcional, default: latest)
TAG=latest
```

Criar `environments/local/.env.example` completo:

```env
# .env.example - Template para ambiente LOCAL

# Caminhos Windows (ajustar para seu sistema)
PORTAINER_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Portainer
NGINX_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/data
NGINX_LETSENCRYPT_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/letsencrypt
NODE_RED_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Node-RED
CODE_PATH=C:/caminho/para/AMG-Data

# MongoDB LOCAL (usar MongoDB no container ou host)
# Container: mongodb://database:27017
# Host: mongodb://host.docker.internal:27017
MONGO_URI=mongodb://database:27017
DB_NAME=Cluster-EasyTek

# MQTT (mesmo que ambiente remoto)
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario
MQTT_PASSWORD=sua_senha

# Gateway LOCAL
GATEWAY_URL=http://localhost:5001

# Secret Key (gerar única para cada ambiente)
SECRET_KEY=sua_chave_local_diferente_de_prod
```

Similar para `environments/dev/.env.example` e `environments/prod/.env.example`.

**Benefícios**:
- ✅ Novo dev sabe exatamente o que preencher
- ✅ Comentários explicam cada variável
- ✅ Exemplos de valores válidos
- ✅ Comandos para gerar valores seguros
- ✅ Previne dessincronização

**Estimativa**: 1-2 horas

---

### 2. Remover Paths Hardcoded {#2-paths-hardcoded}

**Problema Atual**

Múltiplos scripts assumem paths específicos:

**`scripts/build-and-push.ps1:50`**:
```powershell
$CodePath = "E:\Projetos Python\AMG_Data"  # ❌ Hardcoded
```

**`scripts/diagnose-docs.ps1:9`**:
```powershell
$docsPath = "C:\AMG-Infra\docs\procedures"  # ❌ Hardcoded
$composeFile = "C:\AMG-Infra\docker-compose.yml"
```

**`environments/local/.env`**:
```env
PORTAINER_DATA_PATH=C:/AMG-Infra/Docker-Data/Portainer  # ❌ Hardcoded
CODE_PATH=C:/AMG-Infra/AMG-Data
```

**Consequências**:
- ❌ Script falha em máquina diferente
- ❌ Desenvolvedor Linux não consegue rodar scripts Windows
- ❌ CI/CD precisa recriar estrutura de pastas exata

**Solução Proposta**

**Opção 1: Detectar diretório automaticamente**

```powershell
# scripts/build-and-push.ps1 (corrigido)
# Detectar diretório base do repositório
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$CodePath = Join-Path (Split-Path -Parent $RepoRoot) "AMG-Data"

# Verificar se existe
if (-not (Test-Path $CodePath)) {
    Write-Error "Diretório AMG-Data não encontrado em: $CodePath"
    Write-Host "Por favor, defina a variável CODE_PATH no .env"
    exit 1
}
```

**Opção 2: Usar variáveis de ambiente**

```powershell
# scripts/diagnose-docs.ps1 (corrigido)
$RepoRoot = $env:AMG_INFRA_PATH ?? (Get-Location)
$docsPath = Join-Path $RepoRoot "docs\procedures"
$composeFile = Join-Path $RepoRoot "docker-compose.yml"
```

**Para .env local, usar paths relativos quando possível**:
```env
# Relativo ao diretório do compose
PORTAINER_DATA_PATH=./Docker-Data/Portainer
NGINX_DATA_PATH=./Docker-Data/Nginx-Proxy-Manager/data
```

**Benefícios**:
- ✅ Scripts funcionam em qualquer máquina
- ✅ Portável entre Windows/Linux
- ✅ CI/CD simplificado
- ✅ Onboarding mais fácil

**Estimativa**: 2-3 horas

---

### 3. Documentar Variáveis Obrigatórias {#3-variaveis-obrigatorias}

**Problema Atual**

Não há lista centralizada de variáveis obrigatórias. Desenvolvedor precisa:
1. Rodar script
2. Esperar erro
3. Descobrir qual variável falta
4. Repetir

**Solução Proposta**

Criar `ENVIRONMENT_VARIABLES.md`:

```markdown
# 📋 Variáveis de Ambiente

## Obrigatórias (Todos os Ambientes)

| Variável | Descrição | Exemplo | Como Obter |
|----------|-----------|---------|------------|
| MONGO_URI | URI de conexão MongoDB | `mongodb://...` | Ver documentação MongoDB |
| DB_NAME | Nome do database | `Cluster-EasyTek` | Definir conforme projeto |
| MQTT_BROKER_ADDRESS | Endereço do broker MQTT | `xxx.hivemq.cloud` | Console HiveMQ |
| MQTT_BROKER_PORT | Porta MQTT (TLS) | `8883` | Console HiveMQ |
| MQTT_USERNAME | Usuário MQTT | `usuario` | Console HiveMQ |
| MQTT_PASSWORD | Senha MQTT | `senha` | Console HiveMQ |
| SECRET_KEY | Chave secreta da aplicação | 64 chars hex | `python -c '...'` |
| GATEWAY_URL | URL do Event Gateway | `http://event-gateway:5001` | Depende do ambiente |

## Obrigatórias (Dev/Prod apenas)

| Variável | Descrição | Exemplo | Como Obter |
|----------|-----------|---------|------------|
| GITHUB_USER | Usuário GitHub | `usuario` | Seu usuário |
| GITHUB_PAT | Personal Access Token | `ghp_xxx` | https://github.com/settings/tokens |

## Obrigatórias (Local apenas)

| Variável | Descrição | Exemplo Windows | Exemplo Linux |
|----------|-----------|-----------------|---------------|
| PORTAINER_DATA_PATH | Path data Portainer | `C:/AMG-Infra/Docker-Data/Portainer` | `./Docker-Data/Portainer` |
| CODE_PATH | Path repositório AMG-Data | `E:/Projetos/AMG-Data` | `../AMG-Data` |

## Opcionais

| Variável | Descrição | Default | Quando Usar |
|----------|-----------|---------|-------------|
| TAG | Tag da imagem Docker | `latest` | Para versão específica |
| DOCS_PROCEDURES_PATH | Path docs no container | `/app/docs/procedures` | Raramente muda |
```

Adicionar validação em `scripts/up.ps1`:

```powershell
function Test-RequiredEnvVars {
    $required = @(
        'MONGO_URI',
        'DB_NAME',
        'MQTT_BROKER_ADDRESS',
        'MQTT_USERNAME',
        'MQTT_PASSWORD',
        'SECRET_KEY',
        'GATEWAY_URL'
    )

    if ($env -ne 'local') {
        $required += @('GITHUB_USER', 'GITHUB_PAT')
    }

    $missing = @()
    foreach ($var in $required) {
        if (-not (Get-Variable -Name $var -ErrorAction SilentlyContinue)) {
            $missing += $var
        }
    }

    if ($missing.Count -gt 0) {
        Write-Error "ERRO: Variáveis obrigatórias não definidas:"
        $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host "`nConsulte ENVIRONMENT_VARIABLES.md para detalhes"
        exit 1
    }
}

# Chamar antes de iniciar
Test-RequiredEnvVars
```

**Benefícios**:
- ✅ Falha rápida com mensagem clara
- ✅ Desenvolvedor sabe exatamente o que configurar
- ✅ Documentação centralizada
- ✅ Reduz tempo de troubleshooting

**Estimativa**: 1 hora

---

### 4. Separar Credenciais por Ambiente {#4-credenciais-ambiente}

**Problema Atual**

`.env.common` é compartilhado por local, dev e prod:

```env
# .env.common (usado em TODOS os ambientes)
MONGO_URI=mongodb+srv://...
MQTT_PASSWORD=Eletrica@14
SECRET_KEY=572325043802836728583887489361
```

**Riscos**:
- ❌ Desenvolvedor local acessa banco de produção acidentalmente
- ❌ SECRET_KEY igual em todos os ambientes (inseguro)
- ❌ Mudança em `.env.common` afeta todos os ambientes

**Solução Proposta**

**Estrutura nova**:
```
environments/
├── local/
│   ├── .env              # Credenciais LOCAIS (não commitado)
│   ├── .env.example      # Template
│   └── docker-compose.override.yml
├── dev/
│   ├── .env              # Credenciais DEV (não commitado)
│   ├── .env.example      # Template
│   └── docker-compose.override.yml
└── prod/
    ├── .env              # Credenciais PROD (não commitado, usar Secrets)
    ├── .env.example      # Template
    └── docker-compose.override.yml
```

**Remover `.env.common`**, integrar em cada `.env`:

**`environments/local/.env`** (exemplo):
```env
# MongoDB LOCAL (container ou host)
MONGO_URI=mongodb://database:27017
DB_NAME=Cluster-EasyTek-Local

# MQTT (instância de teste)
MQTT_BROKER_ADDRESS=test.hivemq.cloud
MQTT_USERNAME=test_user
MQTT_PASSWORD=test_password

# Secret Key LOCAL (diferente de prod!)
SECRET_KEY=local_key_diferente_prod_...

# Gateway
GATEWAY_URL=http://localhost:5001
```

**`environments/dev/.env`** (exemplo):
```env
# MongoDB DEV
MONGO_URI=mongodb+srv://dev_user:dev_pass@cluster-dev.mongodb.net/...
DB_NAME=Cluster-EasyTek-Dev

# MQTT DEV
MQTT_BROKER_ADDRESS=dev.hivemq.cloud
MQTT_USERNAME=dev_user
MQTT_PASSWORD=dev_password

# Secret Key DEV
SECRET_KEY=dev_key_diferente_de_local_e_prod_...

# Gateway
GATEWAY_URL=http://event-gateway:5001
```

**`environments/prod/.env`** (exemplo - NÃO COMITAR):
```env
# MongoDB PROD (usar AWS Secrets ou similar)
MONGO_URI=mongodb+srv://prod_user:SENHA_FORTE@cluster-prod.mongodb.net/...
DB_NAME=Cluster-EasyTek-Prod

# MQTT PROD
MQTT_BROKER_ADDRESS=prod.hivemq.cloud
MQTT_USERNAME=prod_user
MQTT_PASSWORD=SENHA_FORTE_PROD

# Secret Key PROD (64 chars hex forte)
SECRET_KEY=chave_gerada_com_secrets_token_hex_32_...

# Gateway
GATEWAY_URL=http://event-gateway:5001
```

**Atualizar scripts para carregar .env do ambiente**:

```powershell
# scripts/up.ps1 (linha 10)
$envFile = ".\environments\${env}\.env"  # Apenas este .env
# Remover carregamento de .env.common
```

**Benefícios**:
- ✅ Isolamento total entre ambientes
- ✅ Impossível confundir credenciais
- ✅ SECRET_KEY única por ambiente (segurança)
- ✅ Mudança em um ambiente não afeta outros

**Estimativa**: 3-4 horas

---

## 🟡 Média Prioridade

### 5. Padronizar Nomenclatura de .env {#5-nomenclatura}

**Problema Atual**

Arquivos sem padrão claro:
- `.env` (GitHub PAT)
- `.env.common` (variáveis globais)
- `environments/*/..env` (variáveis específicas)
- `.env.example` (template incompleto)

**Solução Proposta**

**Nomenclatura padronizada**:
```
.env.example                     # Template raiz (variáveis comuns)
environments/local/.env          # Valores reais LOCAL (não commitado)
environments/local/.env.example  # Template LOCAL
environments/dev/.env            # Valores reais DEV (não commitado)
environments/dev/.env.example    # Template DEV
environments/prod/.env           # Valores reais PROD (não commitado, usar Secrets)
environments/prod/.env.example   # Template PROD
```

Remover:
- `.env` (mover conteúdo para `environments/*/..env`)
- `.env.common` (dividir entre ambientes)

**Estimativa**: 2 horas

---

### 6. Documentar Diferenças entre Ambientes {#6-diff-ambientes}

**Problema Atual**

Não há documentação clara de como local/dev/prod diferem.

**Solução Proposta**

Adicionar seção em `ENVIRONMENT_VARIABLES.md`:

```markdown
## Diferenças entre Ambientes

| Aspecto | Local | Dev | Prod |
|---------|-------|-----|------|
| **MongoDB** | Container local OU host | Atlas (cluster dev) | Atlas (cluster prod) |
| **MQTT** | Pode ser mock | HiveMQ dev | HiveMQ prod |
| **SECRET_KEY** | Qualquer (teste) | Forte, única | Muito forte, rotacionada |
| **GATEWAY_URL** | localhost:5001 | event-gateway:5001 | event-gateway:5001 |
| **Build** | `--build` (local) | Pull de GHCR | Pull de GHCR |
| **Volumes** | Paths Windows/Mac | Paths container | Paths container |
| **Auth GHCR** | Não necessária | GITHUB_PAT | GITHUB_PAT |
| **Rede Docker** | Criada local | Externa (Swarm?) | Externa (Swarm?) |

## Fluxo de Deploy

1. **Local**: Desenvolve features, testa localmente
2. **Dev**: Push para branch → CI build → Deploy em dev → Testes de integração
3. **Prod**: Merge para main → CI build → Deploy em prod → Smoke tests
```

**Estimativa**: 1 hora

---

## 🟢 Baixa Prioridade

### 7. Usar Docker Secrets {#7-docker-secrets}

**Problema Atual**

Credenciais em `.env` em texto plano no filesystem.

**Solução Proposta**

Usar Docker Secrets (Swarm) ou volume externo:

```yaml
# docker-compose.yml
services:
  webapp:
    secrets:
      - mongo_uri
      - mqtt_password
      - secret_key

secrets:
  mongo_uri:
    external: true
  mqtt_password:
    external: true
  secret_key:
    external: true
```

Criar secrets:
```bash
echo "mongodb+srv://..." | docker secret create mongo_uri -
echo "senha_mqtt" | docker secret create mqtt_password -
```

Aplicação lê de `/run/secrets/mongo_uri`.

**Estimativa**: 1 dia (requer mudança na aplicação)

---

**Última atualização**: 2026-01-30
