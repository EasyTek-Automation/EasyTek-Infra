# 📚 Documentação Técnica - AMG_Infra

> **Nota**: Este diretório contém documentação para **desenvolvedores**.
> Para procedimentos operacionais, veja `docs/procedures/` (feature da aplicação).

---

## 🚨 ATENÇÃO - PROBLEMAS CRÍTICOS ATIVOS

| Prioridade | Problema | Status | Ação Imediata |
|------------|----------|--------|---------------|
| 🔴 **CRÍTICO** | Credenciais expostas no Git | ⚠️ EM REMEDIAÇÃO | [Ver Plano](./security/CRITICAL-SECURITY-ISSUES.md) |

**AÇÃO NECESSÁRIA**:
1. ✅ Revogar GitHub PAT imediatamente
2. ✅ Resetar senhas MongoDB/MQTT
3. ✅ Remover credenciais do histórico Git

---

## 📂 Estrutura

```
.dev-docs/
├── README.md                    # 👈 Você está aqui
├── security/                    # 🔒 Problemas de segurança
│   ├── README.md
│   └── CRITICAL-SECURITY-ISSUES.md  # 🚨 Credenciais expostas
├── technical-debt/              # ⚠️ Dívidas técnicas
│   ├── README.md                # Índice (21 itens)
│   ├── configuration-improvements.md
│   ├── scripts-improvements.md
│   ├── docker-improvements.md
│   └── documentation-improvements.md
├── guides/                      # 📖 Guias de desenvolvimento
│   ├── SETUP.md                 # Setup completo
│   └── TROUBLESHOOTING.md       # Problemas comuns
└── architecture/                # 🏗️ Arquitetura (futuro)
```

---

## 🚀 Início Rápido

### Para Novos Desenvolvedores

1. **Setup**: Siga **[SETUP.md](./guides/SETUP.md)** passo a passo (30-45 min)
2. **Troubleshooting**: Se houver problema, consulte **[TROUBLESHOOTING.md](./guides/TROUBLESHOOTING.md)**
3. **Contribuir**: Veja [dívidas técnicas](#️-dívida-técnica) priorizadas

### Para Corrigir Problema de Hoje (Dessincronização)

O problema de hoje foi causado por:
- ❌ Credenciais em `.env.common` (deveria ser `.env.example`)
- ❌ Falta de documentação de setup
- ❌ Rede Docker não criada automaticamente

**Prevenir futuros problemas**:
1. ✅ Seguir [Plano de Segurança](./security/CRITICAL-SECURITY-ISSUES.md)
2. ✅ Resolver [dívidas técnicas de Alta Prioridade](#-alta-prioridade)
3. ✅ Usar [SETUP.md](./guides/SETUP.md) para onboarding

---

## 🔒 [Segurança](./security/)

**Status**: 🔴 1 problema crítico ativo

- **[CRITICAL-SECURITY-ISSUES.md](./security/CRITICAL-SECURITY-ISSUES.md)** - Credenciais expostas no Git

**Próximas ações**:
1. Revogar tokens comprometidos
2. Resetar todas as credenciais
3. Remover do histórico Git
4. Criar `.env.example` adequado

---

## ⚠️ [Dívida Técnica](./technical-debt/)

Melhorias identificadas que **não são bugs**, mas aumentam qualidade/manutenibilidade.

**➡️ [Ver lista completa](./technical-debt/README.md)**

### Resumo Rápido

| Categoria | Total | 🔴 Alta | 🟡 Média | 🟢 Baixa | ✅ Concluído |
|-----------|-------|---------|----------|----------|--------------|
| Configuração | 8 | 5 | 2 | 1 | 0 |
| Scripts | 5 | 2 | 2 | 1 | 0 |
| Docker/Compose | 4 | 3 | 1 | 0 | 0 |
| Documentação | 4 | 2 | 2 | 0 | 0 |
| **TOTAL** | **21** | **12** | **7** | **2** | **0** |

### 🔴 Alta Prioridade

Top 5 itens para resolver primeiro:

1. **[Criar .env.example adequado](./technical-debt/configuration-improvements.md#1-env-example)** (1-2h)
   - Previne dessincronização
   - Facilita onboarding

2. **[Remover paths hardcoded](./technical-debt/configuration-improvements.md#2-paths-hardcoded)** (2-3h)
   - Scripts funcionam em qualquer máquina

3. **[Criar rede Docker automaticamente](./technical-debt/docker-improvements.md#1-rede-automatica)** (1h)
   - Previne erro "network not found"

4. **[Criar SETUP.md](./technical-debt/documentation-improvements.md#1-setup)** (3-4h)
   - ✅ JÁ CRIADO!

5. **[Validar variáveis antes de iniciar](./technical-debt/scripts-improvements.md#1-validacao)** (2-3h)
   - Mensagens de erro claras

---

## 📖 [Guias](./guides/)

Guias práticos de desenvolvimento e troubleshooting.

- **[SETUP.md](./guides/SETUP.md)** - Setup completo para novos desenvolvedores (✅ CRIADO)
- **[TROUBLESHOOTING.md](./guides/TROUBLESHOOTING.md)** - Problemas comuns e soluções (✅ CRIADO)

---

## 🏗️ Arquitetura

*(A ser criado no futuro)*

- Arquitetura geral do sistema
- Design decisions
- Padrões e convenções

---

## 🎯 Objetivos Q1 2026

### Segurança
- [ ] Resolver problema crítico de credenciais expostas
- [ ] Implementar pre-commit hooks para prevenir
- [ ] Documentar práticas de segurança

### Dívidas Técnicas
- [ ] Zerar itens de Alta Prioridade de Configuração (5 itens)
- [ ] Criar .env.example completo
- [ ] Remover hardcoding de paths
- [ ] Rede Docker criada automaticamente

### Documentação
- [x] SETUP.md criado
- [x] TROUBLESHOOTING.md criado
- [ ] README.md na raiz do projeto
- [ ] ENVIRONMENT_VARIABLES.md

**Progresso Geral**:
- 🔴 Segurança: 0/1 resolvido (0%)
- ⚠️ Dívidas Técnicas: 0/21 resolvido (0%)
- 📖 Documentação: 2/4 criado (50%)

---

## 📝 Como Usar

### Resolver Dívida Técnica

1. Acesse [technical-debt/README.md](./technical-debt/README.md)
2. Escolha item de prioridade desejada
3. Clique no link para ver detalhes técnicos
4. Implemente seguindo sugestões
5. Marque como concluído no README

### Adicionar Nova Dívida

1. Identifique problema/melhoria
2. Classifique prioridade (Alta/Média/Baixa)
3. Adicione em arquivo apropriado em `technical-debt/`
4. Adicione entrada no `technical-debt/README.md`
5. Atualize tabela de Status Geral

### Reportar Problema de Segurança

1. Documente em `security/`
2. Adicione entrada em `security/README.md`
3. Classifique severidade
4. Crie plano de remediação
5. Notifique equipe imediatamente

---

## 🔄 Manutenção

Atualize esta documentação quando:

- ✅ Identificar novo débito técnico
- ✅ Resolver débito existente
- ✅ Mudança significativa de arquitetura
- ✅ Novo guia necessário
- ✅ Problema de segurança identificado

---

## 📞 Contatos

- **Issues**: https://github.com/EasyTek-Automation/AMG-Infra/issues
- **Equipe**: [adicionar contatos]

---

**Criado em**: 2026-01-30
**Última auditoria**: 2026-01-30
**Mantido por**: Equipe de Desenvolvimento
**Status**: 🔴 Problemas críticos identificados - ação necessária
