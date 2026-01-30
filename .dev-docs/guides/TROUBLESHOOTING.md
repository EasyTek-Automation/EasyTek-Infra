# 🔧 Troubleshooting - AMG_Infra

Problemas comuns e suas soluções.

---

## 🚨 Problemas ao Iniciar

### Erro: "network easytek-net not found"

```
Error response from daemon: network easytek-net not found
```

**Causa**: Rede Docker não foi criada

**Solução**:
```bash
docker network create easytek-net
docker compose up -d
```

---

### Erro: KeyError com variável de ambiente

```
KeyError: 'MONGO_URI'
KeyError: 'SECRET_KEY'
```

**Causa**: Variável não definida em .env

**Solução**:
1. Verificar se `.env.common` existe
2. Verificar se variável está definida
3. Consultar [SETUP.md](./SETUP.md) para criar .env correto

**Listar variáveis carregadas**:
```bash
docker compose config | grep MONGO_URI
```

---

### Erro: "Container failed to start"

**Diagnóstico**:
```bash
# Ver logs do container que falhou
docker compose logs webapp
docker compose logs event-gateway
docker compose logs database

# Ver status
docker ps -a
```

**Causas comuns**:
- Porta já em uso
- Volume com permissões erradas
- Variável de ambiente inválida
- Imagem corrompida

---

## 🔌 Problemas de Conexão

### MongoDB não conecta

**Sintomas**: Logs mostram "connection refused" ou "timeout"

**Verificações**:

1. **MongoDB está rodando?**
   ```bash
   docker ps | grep mongo
   # OU (se MongoDB no host)
   netstat -an | grep 27017
   ```

2. **MONGO_URI correto?**
   ```bash
   # Verificar valor
   docker compose config | grep MONGO_URI

   # Para MongoDB no container
   MONGO_URI=mongodb://database:27017

   # Para MongoDB no host Windows/Mac
   MONGO_URI=mongodb://host.docker.internal:27017
   ```

3. **Testar conexão**:
   ```bash
   docker exec amg-infra-webapp-1 ping database
   # Deve responder se container MongoDB existe
   ```

---

### MQTT não conecta

**Sintomas**: Logs mostram "MQTT connection failed"

**Verificações**:

1. **Credenciais corretas?**
   - MQTT_BROKER_ADDRESS
   - MQTT_USERNAME
   - MQTT_PASSWORD

2. **Firewall bloqueando porta 8883?**
   ```bash
   telnet seu_broker.hivemq.cloud 8883
   # Deve conectar
   ```

3. **Broker está online?**
   - Verificar console HiveMQ Cloud

---

## 🐳 Problemas com Docker

### Porta já em uso

```
Error: bind: address already in use
```

**Identificar processo**:

**Windows**:
```powershell
netstat -ano | findstr :8050
# Anote o PID e mate o processo
taskkill /PID <pid> /F
```

**Linux/Mac**:
```bash
lsof -i :8050
kill -9 <pid>
```

**Ou mudar porta**:
```bash
# Editar docker-compose.yml
ports:
  - "8051:8050"  # Usar porta 8051 ao invés de 8050
```

---

### Volume com permissões erradas

**Sintomas**: "Permission denied" nos logs

**Linux/Mac**:
```bash
# Verificar dono do volume
docker volume inspect node_red_modules

# Corrigir permissões
docker run --rm -v node_red_modules:/data alpine chown -R 1000:1000 /data
```

**Windows**: Geralmente não é problema (Docker Desktop gerencia)

---

### Imagem corrompida

**Sintomas**: Erro ao iniciar container sem causa clara

**Solução**:
```bash
# Remover imagem e refazer pull
docker rmi ghcr.io/easytek-automation/easytek-data/webapp:latest
docker compose pull
docker compose up -d
```

---

## 📦 Problemas de Build

### Build falha por falta de autenticação (GHCR)

```
Error: failed to authorize: failed to fetch oauth token
```

**Causa**: Sem autenticação no GitHub Container Registry

**Solução**:
```bash
# Fazer login no GHCR
echo $GITHUB_PAT | docker login ghcr.io -u $GITHUB_USER --password-stdin
```

Ou definir em `.env`:
```env
GITHUB_USER=seu_usuario
GITHUB_PAT=ghp_seu_token
```

---

### Build lento (dev local)

**Causa**: Docker buildx fazendo build multi-arch

**Solução para dev**:
```bash
# Build apenas para arquitetura local
docker buildx build --platform linux/amd64 -t nome-imagem .
# (sem --push para não enviar ao registry)
```

---

## 🔍 Debug Avançado

### Entrar no container

```bash
# Bash
docker exec -it amg-infra-webapp-1 bash

# Sh (se bash não disponível)
docker exec -it amg-infra-webapp-1 sh

# PowerShell (Windows containers)
docker exec -it nome-container powershell
```

### Verificar variáveis de ambiente no container

```bash
docker exec amg-infra-webapp-1 env | grep MONGO
docker exec amg-infra-webapp-1 printenv MONGO_URI
```

### Verificar conectividade entre containers

```bash
# Do webapp para database
docker exec amg-infra-webapp-1 ping database

# Do webapp para event-gateway
docker exec amg-infra-webapp-1 curl http://event-gateway:5001/health
```

### Logs detalhados

```bash
# Logs em tempo real
docker compose logs -f webapp

# Últimas 100 linhas
docker compose logs --tail=100 webapp

# Com timestamps
docker compose logs -f --timestamps webapp
```

---

## 📞 Ainda com Problemas?

Se problema persistir:

1. **Coletar informações**:
   ```bash
   docker compose config > compose-rendered.yml
   docker compose logs > logs.txt
   docker ps -a > containers.txt
   ```

2. **Verificar documentação**:
   - [SETUP.md](./SETUP.md)
   - [Dívidas Técnicas](../technical-debt/)
   - [Problemas de Segurança](../security/)

3. **Contatar equipe**:
   - Incluir logs
   - Incluir steps to reproduce
   - Incluir ambiente (Windows/Linux, Docker version)

---

**Última atualização**: 2026-01-30
