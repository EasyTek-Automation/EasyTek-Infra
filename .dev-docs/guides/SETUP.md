# 🚀 Guia de Setup - AMG_Infra

Guia completo para configurar o ambiente de desenvolvimento pela primeira vez.

---

## ✅ Pré-requisitos

### Software Necessário

- **Docker Desktop** 4.0+ ([download](https://www.docker.com/products/docker-desktop))
- **Git** 2.30+ ([download](https://git-scm.com/))
- **PowerShell** 7+ (Windows) ou **Bash** (Linux/Mac)
- **Editor de código** (VS Code recomendado)

### Acesso Necessário

- [ ] Acesso ao repositório GitHub
- [ ] Credenciais MongoDB (Atlas ou local)
- [ ] Credenciais MQTT (HiveMQ Cloud)
- [ ] GitHub Personal Access Token (para dev/prod)

---

## 📥 Passo 1: Clone do Repositório

```bash
# Clone
git clone https://github.com/EasyTek-Automation/AMG-Infra.git
cd AMG-Infra

# Verificar branch
git branch
# Deve mostrar: * main
```

---

## 🔧 Passo 2: Configurar Variáveis de Ambiente

### 2.1 Criar .env na Raiz (Dev/Prod apenas)

Se for trabalhar com dev/prod, crie `.env` na raiz:

```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

Edite `.env` e preencha:
```env
GITHUB_USER=seu_usuario_github
GITHUB_PAT=ghp_seu_token_aqui
```

**Gerar GitHub PAT**: https://github.com/settings/tokens
- Scopes necessários: `read:packages`, `write:packages`

### 2.2 Criar .env.common

```bash
# Windows
copy .env.common.example .env.common

# Linux/Mac
cp .env.common.example .env.common
```

Edite `.env.common` com:
```env
# MongoDB
MONGO_URI=mongodb://database:27017  # Para local com container
# OU
MONGO_URI=mongodb://host.docker.internal:27017  # Para MongoDB no host
# OU
MONGO_URI=mongodb+srv://usuario:senha@cluster.mongodb.net/db  # Atlas

DB_NAME=Cluster-EasyTek

# MQTT
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario
MQTT_PASSWORD=sua_senha

# Application
SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')
GATEWAY_URL=http://event-gateway:5001
```

### 2.3 Criar .env do Ambiente (Local)

```bash
# Windows
copy environments\local\.env.example environments\local\.env

# Linux/Mac
cp environments/local/.env.example environments/local/.env
```

Edite `environments/local/.env` ajustando **paths para sua máquina**:

**Windows**:
```env
PORTAINER_DATA_PATH=C:/AMG-Infra/Docker-Data/Portainer
NGINX_DATA_PATH=C:/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/data
NGINX_LETSENCRYPT_PATH=C:/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/letsencrypt
NODE_RED_DATA_PATH=C:/AMG-Infra/Docker-Data/Node-RED
CODE_PATH=C:/caminho/para/AMG-Data
```

**Linux/Mac**:
```env
PORTAINER_DATA_PATH=./Docker-Data/Portainer
NGINX_DATA_PATH=./Docker-Data/Nginx-Proxy-Manager/data
NGINX_LETSENCRYPT_PATH=./Docker-Data/Nginx-Proxy-Manager/letsencrypt
NODE_RED_DATA_PATH=./Docker-Data/Node-RED
CODE_PATH=../AMG-Data
```

---

## 🐳 Passo 3: Configurar Docker

### 3.1 Verificar Docker Rodando

```bash
docker --version
docker compose version
```

### 3.2 Criar Rede Docker

```bash
docker network create easytek-net
```

**Verificar**:
```bash
docker network ls | grep easytek-net
```

### 3.3 Criar Diretórios de Volumes (opcional)

```bash
# Windows
mkdir Docker-Data\Portainer, Docker-Data\Nginx-Proxy-Manager, Docker-Data\Node-RED

# Linux/Mac
mkdir -p Docker-Data/{Portainer,Nginx-Proxy-Manager,Node-RED}
```

---

## 🚀 Passo 4: Iniciar Aplicação

### Ambiente Local

**Windows (PowerShell)**:
```powershell
.\scripts\up.ps1 -env local
```

**Linux/Mac (Bash)**:
```bash
./scripts/up.sh local
```

### Primeira execução (build)

A primeira vez demora mais (5-10 min) pois faz download/build de imagens.

**Aguardar mensagem**:
```
✓ Container nginx-proxy-manager  Healthy
✓ Container webapp               Started
✓ Container event-gateway        Started
✓ Container node-red             Started
SUCESSO: Ambiente 'local' iniciado
```

---

## ✅ Passo 5: Verificar Funcionamento

### 5.1 Verificar Containers

```bash
docker ps
```

Deve mostrar:
- `nginx-proxy-manager`
- `amg-infra-webapp-1`
- `amg-infra-event-gateway-1`
- `amg-infra-node-red-1`
- `amg-infra-database-1` (se MongoDB local)

### 5.2 Acessar Aplicações

- **Webapp**: http://localhost:8050
- **Event Gateway**: http://localhost:5001 (API)
- **Node-RED**: http://localhost:1880
- **Portainer**: https://localhost:9443

### 5.3 Verificar Logs

```bash
# Ver todos os logs
docker compose logs

# Ver logs de serviço específico
docker compose logs webapp
docker compose logs event-gateway
```

---

## 🛑 Parar Aplicação

**Windows**:
```powershell
.\scripts\down.ps1 -env local
```

**Linux/Mac**:
```bash
./scripts/down.sh local
```

---

## 🔍 Troubleshooting

### Erro: "network easytek-net not found"

**Solução**:
```bash
docker network create easytek-net
```

### Erro: "KeyError: 'MONGO_URI'"

**Solução**: Verificar se `.env.common` foi criado e tem `MONGO_URI` definido.

### Erro: "Container failed to start"

**Verificar logs**:
```bash
docker compose logs nome-do-container
```

### Porta já em uso

**Verificar o que está usando**:
```bash
# Windows
netstat -ano | findstr :8050

# Linux/Mac
lsof -i :8050
```

**Mudar porta**: Editar `docker-compose.yml` ou definir variável `WEBAPP_PORT`.

---

## 📚 Próximos Passos

- Ler **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** para problemas comuns
- Ver **[Dívidas Técnicas](../technical-debt/)** para melhorias
- Consultar **[Segurança](../security/)** para boas práticas

---

**Criado**: 2026-01-30
**Tempo estimado de setup**: 30-45 minutos
