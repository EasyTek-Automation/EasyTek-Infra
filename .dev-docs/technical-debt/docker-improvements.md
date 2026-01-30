# 🔧 Melhorias - Docker/Compose

Melhorias na configuração Docker e Docker Compose.

---

## 🔴 Alta Prioridade

### 1. Criar Rede Docker Automaticamente {#1-rede-automatica}

**Problema**: Scripts assumem que rede `easytek-net` já existe

**Arquivo**: `docker-compose.yml:49-50`

**Atual**:
```yaml
networks:
  easytek-net:
    external: true  # ❌ Falha se não existir
```

**Erro em ambiente novo**:
```
Error response from daemon: network easytek-net not found
```

**Solução 1: Criar se não existir (scripts)**

```powershell
# scripts/up.ps1 - Adicionar antes de docker compose
if (-not (docker network ls --format "{{.Name}}" | Select-String "easytek-net")) {
    Write-Host "Criando rede Docker easytek-net..."
    docker network create easytek-net
}
```

**Solução 2: Não usar external (mais simples)**

```yaml
networks:
  easytek-net:
    name: easytek-net
    driver: bridge
    # Sem 'external: true'
```

**Recomendação**: Solução 2 (mais simples)

**Estimativa**: 1 hora

---

### 2. Remover user:root do Node-RED {#2-node-red-root}

**Problema**: Container rodando como root (risco de segurança)

**Arquivo**: `docker-compose.yml:35`

**Atual**:
```yaml
node-red:
  user: root  # ❌ Inseguro
```

**Investigar**:
- Por que foi necessário usar `root`?
- Problema de permissões em volumes?

**Solução**:
```yaml
node-red:
  user: "1000:1000"  # UID:GID do usuário
  volumes:
    - node_red_modules:/data/node_modules:rw
  # Garantir que volume tem permissões corretas
```

**Criar volume com permissões adequadas**:
```bash
docker volume create node_red_modules
docker run --rm -v node_red_modules:/data alpine chown -R 1000:1000 /data
```

**Estimativa**: 2-3 horas (testar permissões)

---

### 3. Não Expor MongoDB em Prod {#3-mongodb-exposto}

**Problema**: MongoDB exposto na porta 27017 sem autenticação forte

**Arquivo**: `environments/prod/docker-compose.override.yml:23-24`

**Atual**:
```yaml
database:
  ports:
    - "27017:27017"  # ❌ Exposto publicamente
```

**Solução**: Remover mapeamento de porta em prod

```yaml
database:
  # Sem 'ports' - apenas acessível por containers na mesma rede
  # Se precisar acessar externamente, usar SSH tunnel
```

**Acesso via SSH tunnel (quando necessário)**:
```bash
ssh -L 27017:localhost:27017 usuario@servidor-prod
# Conectar em localhost:27017 localmente
```

**Estimativa**: 1 hora

---

### 4. Usar Variáveis para Portas {#4-portas-variaveis}

**Problema**: Portas hardcoded (difícil customizar, conflitos)

**Arquivo**: `docker-compose.yml`

**Atual**:
```yaml
webapp:
  ports:
    - "8050:8050"  # ❌ Hardcoded

event-gateway:
  ports:
    - "5001:5001"  # ❌ Hardcoded
```

**Solução**:
```yaml
webapp:
  ports:
    - "${WEBAPP_PORT:-8050}:8050"

event-gateway:
  ports:
    - "${GATEWAY_PORT:-5001}:5001"
```

Adicionar em `.env.example`:
```env
# Portas (opcional, ajustar se houver conflito)
WEBAPP_PORT=8050
GATEWAY_PORT=5001
NODE_RED_PORT=1880
```

**Estimativa**: 1-2 horas

---

## 🟡 Média Prioridade

### 5. Adicionar Healthchecks {#5-healthchecks}

**Problema**: Containers sem healthcheck (difícil saber se estão prontos)

**Solução**:
```yaml
webapp:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8050/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s

event-gateway:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
    interval: 30s
    timeout: 10s
    retries: 3

database:
  healthcheck:
    test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
    interval: 10s
    timeout: 5s
    retries: 3
```

**Benefícios**:
- ✅ `docker compose up --wait` espera containers estarem saudáveis
- ✅ Restart automático se falhar
- ✅ Melhor visibilidade de problemas

**Estimativa**: 2 horas

---

**Última atualização**: 2026-01-30
