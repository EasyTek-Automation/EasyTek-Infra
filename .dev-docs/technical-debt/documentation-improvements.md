# 🔧 Melhorias - Documentação

Documentação faltante e melhorias necessárias.

---

## 🔴 Alta Prioridade

### 1. Criar SETUP.md {#1-setup}

**Problema**: Não há guia de setup para novos desenvolvedores

**Consequências**:
- ❌ Onboarding lento (horas/dias ao invés de minutos)
- ❌ Perguntas repetitivas
- ❌ Erros comuns não documentados

**Solução**: Ver `.dev-docs/guides/SETUP.md` (será criado)

**Conteúdo necessário**:
- Pré-requisitos (Docker, Git, etc.)
- Clone do repositório
- Configuração de .env
- Criação de rede Docker
- Primeiro `docker-compose up`
- Verificação de funcionamento
- Troubleshooting básico

**Estimativa**: 3-4 horas

---

### 2. Criar README.md na Raiz {#2-readme}

**Problema**: Não há README principal do projeto

**Consequências**:
- ❌ Ninguém sabe o que é o projeto
- ❌ Sem badges de status
- ❌ Sem links para documentação

**Solução**:
```markdown
# AMG Infra

> Infraestrutura Docker para o sistema EasyTek AMG

## 🚀 Quick Start

\`\`\`bash
# Clone e configure
git clone https://github.com/EasyTek-Automation/AMG-Infra.git
cd AMG-Infra
cp .env.example .env
cp .env.common.example .env.common
# Edite .env e .env.common com suas credenciais

# Inicie (ambiente local)
./scripts/up.ps1 -env local
\`\`\`

## 📚 Documentação

- **[Setup Completo](./dev-docs/guides/SETUP.md)** - Guia passo a passo
- **[Troubleshooting](./dev-docs/guides/TROUBLESHOOTING.md)** - Problemas comuns
- **[Variáveis de Ambiente](./dev-docs/guides/ENVIRONMENT_VARIABLES.md)** - Configuração

## 🏗️ Arquitetura

- **webapp**: Aplicação Dash (porta 8050)
- **event-gateway**: Gateway de eventos MQTT (porta 5001)
- **node-red**: Automação (porta 1880)
- **database**: MongoDB (porta 27017 - apenas local)

## 🔧 Desenvolvimento

- **[Dívidas Técnicas](./dev-docs/technical-debt/)** - Melhorias identificadas
- **[Segurança](./dev-docs/security/)** - Questões de segurança

## 📝 Licença

Proprietário - EasyTek Automation
\`\`\`

**Estimativa**: 1-2 horas

---

## 🟡 Média Prioridade

### 3. Criar TROUBLESHOOTING.md {#3-troubleshooting}

**Problema**: Não há guia de problemas comuns

**Solução**: Documentar problemas frequentes

**Conteúdo**:
```markdown
# 🔧 Troubleshooting

## Rede Docker não existe

**Erro**:
\`\`\`
Error: network easytek-net not found
\`\`\`

**Solução**:
\`\`\`bash
docker network create easytek-net
\`\`\`

## Variável não definida

**Erro**:
\`\`\`
KeyError: 'MONGO_URI'
\`\`\`

**Solução**:
1. Copie `.env.example` para `.env`
2. Preencha com valores reais
3. Consulte `ENVIRONMENT_VARIABLES.md`

## Container não inicia

**Verificar logs**:
\`\`\`bash
docker compose logs webapp
docker compose logs event-gateway
\`\`\`

## MongoDB não conecta

**Verificar**:
1. MONGO_URI está correto?
2. MongoDB está rodando? `docker ps | grep mongo`
3. Firewall bloqueando porta 27017?
\`\`\`

**Estimativa**: 2-3 horas

---

### 4. Comentar Scripts Adequadamente {#4-comentarios}

**Problema**: Scripts com comentários superficiais

**Solução**: Adicionar comentários explicativos

**Exemplo (scripts/up.ps1)**:
```powershell
# Valida que o ambiente é válido (local, dev ou prod)
if ($env -notin @('local', 'dev', 'prod')) {
    Write-Error "Ambiente inválido. Use: local, dev ou prod"
    exit 1
}

# Carrega variáveis de ambiente do arquivo específico do ambiente
# Exemplo: environments/local/.env
$envFile = ".\environments\${env}\.env"

# Verifica se arquivo existe antes de tentar carregar
if (-not (Test-Path $envFile)) {
    Write-Error "Arquivo $envFile não encontrado"
    Write-Host "Copie .env.example para .env e preencha com valores reais"
    exit 1
}
```

**Estimativa**: 2 horas

---

**Última atualização**: 2026-01-30
