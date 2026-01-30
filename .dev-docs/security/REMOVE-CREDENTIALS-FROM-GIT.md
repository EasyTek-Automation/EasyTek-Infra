# 🗑️ Guia: Remover Credenciais do Histórico Git

> **Guia passo a passo para remover credenciais expostas do histórico Git**
>
> **Quando usar**: Quando credenciais foram commitadas acidentalmente
>
> **Tempo estimado**: 15-30 minutos

---

## ⚠️ **IMPORTANTE: Credenciais JÁ ESTÃO COMPROMETIDAS**

Mesmo removendo do Git:
- ❌ As credenciais **já estiveram públicas** no GitHub
- ❌ Podem ter sido **indexadas** por scanners de secrets
- ❌ Podem ter sido **acessadas** por terceiros

**Por isso**: Você **DEVE** revogar/trocar as credenciais de qualquer forma!

Remover do Git é importante para:
- ✅ Evitar exposição futura
- ✅ Limpar o histórico
- ✅ Boas práticas

---

## 📋 **CHECKLIST PRÉ-EXECUÇÃO**

Antes de começar, certifique-se:

- [ ] Você tem **backup** dos arquivos importantes (caso precise reverter)
- [ ] Não há **trabalho não commitado** importante
- [ ] Você está na **branch main**
- [ ] Você tem **permissões de admin** no repositório GitHub
- [ ] Toda a **equipe está avisada** (histórico será reescrito)

---

## 🚀 **PASSO 1: Preparação e Backup**

### 1.1 Verificar estado atual

```powershell
cd "E:\Projetos Python\AMG_Infra"
git status
git log --oneline -5
```

**Esperado**: Branch limpa, sem mudanças pendentes.

### 1.2 Criar backup completo

```powershell
cd "E:\Projetos Python"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item -Path "AMG_Infra" -Destination "AMG_Infra_BACKUP_$timestamp" -Recurse
Write-Host "Backup criado em: AMG_Infra_BACKUP_$timestamp"
```

**Checkpoint**: Verificar que pasta de backup foi criada.

```powershell
ls | Select-String "BACKUP"
```

---

## 🔧 **PASSO 2: Instalar git-filter-repo**

### 2.1 Instalar via pip

```powershell
pip install git-filter-repo
```

### 2.2 Verificar instalação

```powershell
git filter-repo --version
```

**Esperado**: Mostrar versão (ex: `git-filter-repo 2.38.0`)

**Se erro "comando não encontrado"**:
```powershell
# Instalar manualmente
pip install --user git-filter-repo

# Ou baixar script direto
# https://github.com/newren/git-filter-repo/blob/main/git-filter-repo
```

---

## 🗑️ **PASSO 3: Remover Credenciais do Histórico**

### 3.1 Voltar para o repositório

```powershell
cd "E:\Projetos Python\AMG_Infra"
```

### 3.2 Executar git-filter-repo

**⚠️ ATENÇÃO**: Este comando **reescreve TODO o histórico Git**.

```powershell
git filter-repo --invert-paths `
  --path .env `
  --path .env.common `
  --path environments/local/.env `
  --force
```

**O que acontece**:
- Remove `.env`, `.env.common`, `environments/local/.env` de TODOS os commits
- Reescreve hashes de todos os commits
- Pode demorar 30 segundos a 2 minutos

**Saída esperada**:
```
Parsed 156 commits
New history written in 1.23 seconds...
Completely finished after 1.45 seconds.
```

### 3.3 Verificar que arquivos foram removidos

```powershell
# Verificar que .env não existe mais no histórico
git log --all --full-history --oneline -- .env
git log --all --full-history --oneline -- .env.common
```

**Esperado**: Nenhum resultado (arquivos não existem no histórico).

### 3.4 Verificar que arquivos .dev-docs ainda existem

```powershell
git log --oneline -5
ls .dev-docs/
```

**Esperado**: Commits recentes ainda existem, `.dev-docs` intacto.

---

## 📝 **PASSO 4: Criar .env.example (Sem Credenciais)**

### 4.1 Criar .env.example na raiz

```powershell
@"
# .env.example - Template de configuração
# Copie para .env e preencha com valores reais

# GitHub Container Registry (obrigatório para dev/prod)
# Gerar em: https://github.com/settings/tokens
GITHUB_USER=seu_usuario_github
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
"@ | Out-File -FilePath ".env.example" -Encoding UTF8
```

### 4.2 Criar .env.common.example

```powershell
@"
# .env.common.example - Template de variáveis globais
# Copie para .env.common e preencha com valores reais

# MongoDB (obrigatório)
# Exemplo Local: mongodb://database:27017
# Exemplo Cloud: mongodb+srv://usuario:senha@cluster.mongodb.net/database
MONGO_URI=mongodb+srv://usuario:senha@cluster.mongodb.net/?retryWrites=true&w=majority
DB_NAME=nome_do_banco

# MQTT Broker (obrigatório)
MQTT_BROKER_ADDRESS=seu_broker.hivemq.cloud
MQTT_BROKER_PORT=8883
MQTT_USERNAME=seu_usuario_mqtt
MQTT_PASSWORD=sua_senha_mqtt

# Application Secret (obrigatório)
# Gerar com: python -c 'import secrets; print(secrets.token_hex(32))'
SECRET_KEY=sua_chave_secreta_64_caracteres_hexadecimais

# Event Gateway (obrigatório)
GATEWAY_URL=http://event-gateway:5001
"@ | Out-File -FilePath ".env.common.example" -Encoding UTF8
```

### 4.3 Atualizar environments/local/.env.example

```powershell
@"
# .env.example - Template para ambiente LOCAL

# Caminhos Windows (ajustar para seu sistema)
PORTAINER_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Portainer
NGINX_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/data
NGINX_LETSENCRYPT_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Nginx-Proxy-Manager/letsencrypt
NODE_RED_DATA_PATH=C:/caminho/para/AMG-Infra/Docker-Data/Node-RED
CODE_PATH=C:/caminho/para/AMG-Data

# MongoDB LOCAL (usar MongoDB no container)
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
"@ | Out-File -FilePath "environments\local\.env.example" -Encoding UTF8 -Force
```

### 4.4 Verificar .gitignore

```powershell
cat .gitignore | Select-String "\.env"
```

**Esperado**: Deve ter linhas como:
```
.env
.env.local
*.env
!*.env.example
```

Se não tiver, adicione:

```powershell
@"
.env
.env.local
.env.*.local
environments/*/.env
!environments/*/.env.example
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8 -Append
```

### 4.5 Commit dos arquivos exemplo

```powershell
git add .env.example .env.common.example environments/local/.env.example .gitignore
git commit -m "security: adicionar templates .env.example sem credenciais

- Criar .env.example com template de variáveis
- Criar .env.common.example para variáveis globais
- Atualizar .env.example de cada ambiente
- Garantir .gitignore correto para .env

Histórico Git foi limpo de credenciais expostas."
```

---

## 🚀 **PASSO 5: Force Push para Remoto**

### 5.1 Reconectar remote (git-filter-repo remove remotes)

```powershell
git remote add origin https://github.com/EasyTek-Automation/AMG-Infra.git
```

### 5.2 Verificar remote

```powershell
git remote -v
```

**Esperado**:
```
origin  https://github.com/EasyTek-Automation/AMG-Infra.git (fetch)
origin  https://github.com/EasyTek-Automation/AMG-Infra.git (push)
```

### 5.3 **Force push** (reescreve histórico remoto)

⚠️ **ATENÇÃO**: Este comando sobrescreve o histórico no GitHub!

```powershell
# Push de todos os branches
git push origin --force --all

# Push de todas as tags
git push origin --force --tags
```

**Esperado**:
```
+ 12ab34c...56ef78g main -> main (forced update)
```

**Se pedir autenticação**: Use GitHub PAT ou configure credenciais.

---

## ✅ **PASSO 6: Verificação Final**

### 6.1 Verificar no GitHub

1. Acesse: https://github.com/EasyTek-Automation/AMG-Infra
2. Vá em **Commits** (histórico)
3. Procure por commits antigos que tinham `.env`
4. Clique em um commit antigo
5. Verifique que `.env` e `.env.common` **NÃO aparecem** mais

### 6.2 Verificar localmente

```powershell
# Buscar por "GITHUB_PAT" no histórico (não deve achar)
git log --all -p -S "REDACTED_PAT_REMOVED_FROM_HISTORY"

# Buscar por "Eletrica14" (senha) no histórico (não deve achar)
git log --all -p -S "Eletrica14"
```

**Esperado**: Nenhum resultado.

### 6.3 Verificar que .env.example existe

```powershell
ls .env.example, .env.common.example
cat .env.example
```

**Esperado**: Arquivos existem, SEM credenciais reais.

---

## 👥 **PASSO 7: Notificar Equipe**

### 7.1 Avisar toda a equipe

Envie mensagem para todos os desenvolvedores:

```
🚨 HISTÓRICO GIT REESCRITO - AÇÃO NECESSÁRIA

O histórico do repositório AMG-Infra foi reescrito para remover
credenciais expostas. TODOS devem refazer o clone:

1. Backup local (se houver trabalho não commitado):
   cd ..
   mv AMG_Infra AMG_Infra_OLD

2. Clone limpo:
   git clone https://github.com/EasyTek-Automation/AMG-Infra.git
   cd AMG_Infra

3. Configurar .env (copiar de .env.example e preencher com NOVAS credenciais)
   cp .env.example .env
   cp .env.common.example .env.common
   # Editar e preencher

IMPORTANTE: As credenciais antigas foram REVOGADAS.
Use apenas as NOVAS credenciais fornecidas separadamente.
```

---

## 🔐 **PASSO 8: Revogar Credenciais Antigas**

Mesmo tendo removido do Git, você **DEVE** revogar/trocar:

### 8.1 Revogar GitHub PAT

1. Acesse: https://github.com/settings/tokens
2. Localize token `REDACTED_PAT_REMOVED_FROM_HISTORY`
3. Clique em **Delete** ou **Revoke**
4. Gere um **novo token** com escopo mínimo
5. Armazene em gerenciador de senhas

### 8.2 Resetar MongoDB

1. MongoDB Atlas: https://cloud.mongodb.com/
2. **Database Access** → usuário `rgustavo32s`
3. **Edit Password** → gerar nova senha forte
4. Atualizar em `.env.common` local (NÃO commitar)

### 8.3 Resetar MQTT

1. HiveMQ Cloud: https://console.hivemq.cloud/
2. **Access Management** → usuário `rgustavo32`
3. Gerar nova senha
4. Atualizar em `.env.common` local

### 8.4 Gerar nova SECRET_KEY

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

Copiar resultado para `.env.common` local.

---

## ⚠️ **E SE ALGO DER ERRADO?**

### Reverter localmente

```powershell
cd "E:\Projetos Python"
rm -r AMG_Infra
mv AMG_Infra_BACKUP_* AMG_Infra
cd AMG_Infra
```

### Reverter no remoto

Se já fez push mas quer voltar:

```powershell
# Use o backup para refazer push
cd "E:\Projetos Python\AMG_Infra_BACKUP_*"
git push origin --force --all
```

---

## 📊 **Resumo de Comandos (para referência rápida)**

```powershell
# 1. Backup
cd "E:\Projetos Python"
Copy-Item AMG_Infra AMG_Infra_BACKUP_$(Get-Date -Format 'yyyyMMdd_HHmmss') -Recurse

# 2. Instalar ferramenta
pip install git-filter-repo

# 3. Remover arquivos
cd AMG_Infra
git filter-repo --invert-paths --path .env --path .env.common --path environments/local/.env --force

# 4. Criar .env.example (ver comandos detalhados acima)

# 5. Reconectar remote
git remote add origin https://github.com/EasyTek-Automation/AMG-Infra.git

# 6. Force push
git push origin --force --all
git push origin --force --tags

# 7. Verificar
git log --all -p -S "REDACTED_PAT_REMOVED_FROM_HISTORY"
```

---

## ✅ **Checklist Final**

Quando terminar, confirme:

- [ ] Backup criado
- [ ] git-filter-repo instalado e executado
- [ ] Credenciais removidas do histórico (verificado com git log -S)
- [ ] .env.example criados (sem credenciais)
- [ ] .gitignore atualizado
- [ ] Force push realizado
- [ ] Verificado no GitHub que arquivos sumiram
- [ ] Equipe notificada
- [ ] GitHub PAT revogado
- [ ] Senhas MongoDB/MQTT resetadas
- [ ] Nova SECRET_KEY gerada

---

## 📚 Referências

- **git-filter-repo**: https://github.com/newren/git-filter-repo
- **BFG Repo-Cleaner**: https://rtyley.github.io/bfg-repo-cleaner/
- **GitHub Docs - Removing sensitive data**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

---

**Criado**: 2026-01-30
**Última atualização**: 2026-01-30
**Tempo estimado**: 15-30 minutos
