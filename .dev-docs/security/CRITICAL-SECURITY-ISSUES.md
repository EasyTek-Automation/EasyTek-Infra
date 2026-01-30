# 🚨 PROBLEMAS CRÍTICOS DE SEGURANÇA

> **STATUS**: 🔴 CRÍTICO - AÇÃO IMEDIATA NECESSÁRIA
> **Data de Descoberta**: 2026-01-30
> **Prioridade**: MÁXIMA

---

## ⚠️ RESUMO EXECUTIVO

Este repositório contém **credenciais expostas no histórico Git** que comprometem a segurança do projeto.

**Impacto**:
- ❌ GitHub PAT exposto (acesso total ao repositório)
- ❌ Senha MongoDB exposta (acesso ao banco de dados de produção)
- ❌ Senha MQTT exposta (acesso ao broker IoT)
- ❌ SECRET_KEY exposta (comprometimento de sessões)

**Ação Imediata**: Seguir [Plano de Remediação](#-plano-de-remediação-imediata) abaixo.

---

## 🔍 CREDENCIAIS COMPROMETIDAS

### 1. GitHub Personal Access Token (PAT)

**Arquivo**: `.env` (linha 1-2)
**Status**: ✅ VERSIONADO NO GIT (público no histórico)

```env
GITHUB_USER="rgustavo32"
GITHUB_PAT="REDACTED_PAT_REMOVED_FROM_HISTORY"
```

**Risco**:
- Token com acesso total ao repositório
- Permite push, pull, criação de releases
- Pode ser usado para comprometer CI/CD
- Histórico Git mantém o token permanentemente

**Escopo do Token**: Verificar em https://github.com/settings/tokens

---

### 2. Credenciais MongoDB Atlas

**Arquivo**: `.env.common` (linha 1)
**Status**: ✅ VERSIONADO NO GIT

```env
MONGO_URI=mongodb+srv://rgustavo32s:Eletrica14@cluster-easytek.eljwyem.mongodb.net/?retryWrites=true&w=majority&appName=Cluster-EasyTek
```

**Credenciais Expostas**:
- **Usuário**: `rgustavo32s`
- **Senha**: `Eletrica14`
- **Cluster**: `cluster-easytek.eljwyem.mongodb.net`
- **Database**: `Cluster-EasyTek`

**Risco**:
- Acesso total ao banco de dados de produção
- Leitura/escrita/exclusão de todos os dados
- Possibilidade de exfiltração de dados sensíveis
- Dados de produção, desenvolvimento e teste comprometidos

---

### 3. Credenciais MQTT/HiveMQ

**Arquivo**: `.env.common` (linhas 4-6)
**Status**: ✅ VERSIONADO NO GIT

```env
MQTT_BROKER_ADDRESS=d97688cddf164314b10b548c2d44208b.s1.eu.hivemq.cloud
MQTT_USERNAME=rgustavo32
MQTT_PASSWORD=Eletrica@14
```

**Risco**:
- Acesso ao broker MQTT (IoT)
- Publicação de mensagens maliciosas
- Leitura de dados de sensores/equipamentos
- Possível controle de equipamentos industriais

---

### 4. SECRET_KEY da Aplicação

**Arquivo**: `.env.common` (linha 7)
**Status**: ✅ VERSIONADO NO GIT

```env
SECRET_KEY="572325043802836728583887489361"
```

**Risco**:
- Comprometimento de sessões de usuários
- Falsificação de tokens JWT (se usado)
- Bypass de autenticação
- **Adicional**: SECRET_KEY é numérica e fraca (apenas 36 caracteres decimais)

---

### 5. Duplicação em `environments/local/.env`

**Arquivo**: `environments/local/.env` (linhas 13-15)
**Status**: ✅ VERSIONADO NO GIT

```env
MQTT_PASSWORD=Eletrica@14
SECRET_KEY="572325043802836728583887489361"
```

**Problema**: Mesmas credenciais repetidas, aumentando exposição.

---

## 🛡️ PLANO DE REMEDIAÇÃO IMEDIATA

### Passo 1: Revogar GitHub PAT (5 min)

1. Acesse: https://github.com/settings/tokens
2. Localize o token `REDACTED_PAT_REMOVED_FROM_HISTORY`
3. Clique em **Delete** / **Revoke**
4. Gere um novo token com escopo mínimo necessário
5. Armazene em **local seguro** (1Password, Bitwarden, etc.)
6. **NÃO ADICIONE AO GIT**

**Comando para gerar novo token via CLI**:
```bash
# Usar GitHub CLI para gerar token com escopo específico
gh auth login
# Seguir prompts e salvar token em gerenciador de senhas
```

---

### Passo 2: Resetar Senha MongoDB (10 min)

1. Acesse MongoDB Atlas: https://cloud.mongodb.com/
2. Navegue até: **Database Access** → Usuário `rgustavo32s`
3. Clique em **Edit** → **Edit Password**
4. Gere senha forte: `python -c 'import secrets; print(secrets.token_urlsafe(32))'`
5. Atualize MONGO_URI em arquivo `.env` **LOCAL** (não comitar)
6. Teste conexão antes de continuar

**Verificar aplicações conectadas**:
- Webapp
- Event Gateway
- Scripts de processamento

---

### Passo 3: Resetar Credenciais MQTT (10 min)

1. Acesse HiveMQ Cloud: https://console.hivemq.cloud/
2. Navegue até: **Access Management** → Usuário `rgustavo32`
3. Gere nova senha forte
4. Atualize MQTT_PASSWORD em arquivo `.env` **LOCAL**
5. Reinicie serviços que usam MQTT

---

### Passo 4: Gerar Nova SECRET_KEY (2 min)

```bash
# Gerar SECRET_KEY forte (64 caracteres hexadecimais)
python -c 'import secrets; print(secrets.token_hex(32))'
```

Exemplo de output: `a1b2c3d4e5f6...` (64 caracteres)

Atualizar em arquivo `.env` **LOCAL**.

---

### Passo 5: Remover Credenciais do Histórico Git (30 min)

⚠️ **CUIDADO**: Esta operação reescreve o histórico do Git.

**Backup primeiro**:
```bash
# Criar backup do repositório
cd "E:\Projetos Python"
cp -r AMG_Infra AMG_Infra_BACKUP_$(date +%Y%m%d)
```

**Opção A: git-filter-repo (recomendado)**

```bash
# Instalar git-filter-repo
pip install git-filter-repo

# Remover arquivos do histórico
cd "E:\Projetos Python\AMG_Infra"
git filter-repo --invert-paths --path .env --path .env.common --path environments/local/.env --force

# Recriar arquivos sem credenciais
# (ver Passo 6)
```

**Opção B: BFG Repo-Cleaner**

```bash
# Download BFG: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --delete-files .env
java -jar bfg.jar --delete-files .env.common
java -jar bfg.jar --delete-folders environments

git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Push forçado** (coordenar com equipe):
```bash
git push origin --force --all
git push origin --force --tags
```

⚠️ **Avisar toda a equipe** para refazer `git clone` do repositório limpo.

---

### Passo 6: Criar Arquivos .env Seguros (15 min)

#### 6.1 Atualizar `.gitignore`

Verificar se já ignora (já deve estar correto):
```gitignore
.env
.env.local
.env.*.local
environments/*/.env
!environments/*/.env.example
```

#### 6.2 Criar `.env.example` na raiz

```bash
# Arquivo: .env.example (SIM, commitar este)
# GitHub Container Registry (para dev/prod)
GITHUB_USER=seu_usuario_github
GITHUB_PAT=seu_personal_access_token_aqui
```

#### 6.3 Criar `.env.common.example`

```bash
# Arquivo: .env.common.example (SIM, commitar este)

# MongoDB (obrigatório)
MONGO_URI=mongodb+srv://usuario:senha@cluster.mongodb.net/database?retryWrites=true&w=majority
DB_NAME=nome_do_database

# MQTT Broker (obrigatório)
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario_mqtt
MQTT_PASSWORD=sua_senha_mqtt_forte

# Application Secret (obrigatório - gerar com: python -c 'import secrets; print(secrets.token_hex(32))')
SECRET_KEY=sua_secret_key_64_caracteres_hexadecimais

# Event Gateway (obrigatório)
GATEWAY_URL=http://event-gateway:5001
```

#### 6.4 Criar `.env.example` em cada ambiente

**`environments/local/.env.example`**:
```bash
# Caminhos para volumes Docker (LOCAL - Windows)
PORTAINER_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Portainer
NGINX_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/data
NGINX_LETSENCRYPT_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/letsencrypt
NODE_RED_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Node-RED
CODE_PATH=C:/caminho/para/AMG-Data

# MongoDB (LOCAL - usar host.docker.internal para MongoDB local)
MONGO_URI=mongodb://host.docker.internal:27017
DB_NAME=Cluster-EasyTek

# MQTT (mesmo que .env.common)
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario
MQTT_PASSWORD=sua_senha

# Gateway (LOCAL)
GATEWAY_URL=http://localhost:5001

# Application
SECRET_KEY=sua_secret_key_aqui
```

**`environments/dev/.env.example`** e **`environments/prod/.env.example`**:
(similar, ajustando paths para Linux se necessário)

---

### Passo 7: Criar .env Reais Localmente (NÃO COMITAR)

```bash
# Copiar exemplos e preencher com valores reais
cp .env.example .env
cp .env.common.example .env.common
cp environments/local/.env.example environments/local/.env

# Editar cada arquivo e substituir valores de exemplo
# por credenciais REAIS geradas nos passos anteriores
```

⚠️ **NUNCA** comitar arquivos `.env` reais!

---

## ✅ CHECKLIST DE VERIFICAÇÃO

Após remediação, verificar:

- [ ] GitHub PAT revogado
- [ ] Novo GitHub PAT gerado e armazenado em segurança
- [ ] Senha MongoDB resetada
- [ ] Senha MQTT resetada
- [ ] Nova SECRET_KEY gerada (64 chars hex)
- [ ] Arquivos `.env` removidos do histórico Git
- [ ] Push forçado realizado
- [ ] Equipe notificada para refazer clone
- [ ] `.env.example` criado e commitado
- [ ] `.env.common.example` criado e commitado
- [ ] `.env` reais criados localmente (NÃO commitados)
- [ ] `.gitignore` verificado
- [ ] Aplicação testada com novas credenciais
- [ ] Documentado em log de incidentes

---

## 📊 IMPACTO E LIÇÕES APRENDIDAS

### Causa Raiz

1. **Falta de .gitignore adequado** (corrigido)
2. **Falta de .env.example** como template
3. **Commit acidental** de arquivos de configuração real
4. **Falta de validação pré-commit** (hooks)

### Prevenção Futura

1. **Implementar pre-commit hooks**:
   ```bash
   # Instalar pre-commit
   pip install pre-commit

   # Criar .pre-commit-config.yaml
   # (adicionar verificação de secrets)
   ```

2. **Usar gerenciador de secrets**:
   - Para local: 1Password, Bitwarden
   - Para CI/CD: GitHub Secrets
   - Para produção: AWS Secrets Manager, Vault

3. **Code review obrigatório**:
   - Nunca permitir commit direto em main
   - Pull requests com revisão de 2+ pessoas

4. **Scan automático de secrets**:
   - GitGuardian
   - TruffleHog
   - git-secrets

---

## 📞 CONTATOS DE EMERGÊNCIA

Se detectar uso não autorizado:

1. **GitHub**: Reportar em https://github.com/security
2. **MongoDB Atlas**: Support via console
3. **HiveMQ**: Support ticket
4. **Equipe de Segurança**: [adicionar contato]

---

**Documento criado**: 2026-01-30
**Última atualização**: 2026-01-30
**Responsável**: Equipe de Desenvolvimento
**Status**: 🔴 EM REMEDIAÇÃO
