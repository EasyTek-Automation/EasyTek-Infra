# 🔒 Segurança

Documentação de questões de segurança, vulnerabilidades e planos de remediação.

---

## 🚨 PROBLEMAS ATIVOS

| Prioridade | Problema | Status | Documento |
|------------|----------|--------|-----------|
| 🔴 **CRÍTICO** | Credenciais expostas no Git | ⚠️ EM REMEDIAÇÃO | [CRITICAL-SECURITY-ISSUES.md](./CRITICAL-SECURITY-ISSUES.md) |

---

## 📋 Histórico de Incidentes

| Data | Incidente | Severidade | Status | Link |
|------|-----------|------------|--------|------|
| 2026-01-30 | Credenciais no histórico Git | CRÍTICO | Em remediação | [CRITICAL-SECURITY-ISSUES.md](./CRITICAL-SECURITY-ISSUES.md) |

---

## ✅ PROBLEMAS RESOLVIDOS

*(Nenhum ainda)*

---

## 🛡️ Práticas de Segurança

### O que NÃO fazer

- ❌ NUNCA comitar arquivos `.env` com credenciais reais
- ❌ NUNCA usar senhas fracas ou previsíveis
- ❌ NUNCA expor portas de banco de dados diretamente
- ❌ NUNCA usar `root` em containers sem necessidade

### O que SEMPRE fazer

- ✅ Usar `.env.example` como template (sem valores reais)
- ✅ Usar gerenciador de senhas (1Password, Bitwarden)
- ✅ Validar `.gitignore` antes de commitar
- ✅ Code review obrigatório
- ✅ Gerar SECRET_KEY forte: `python -c 'import secrets; print(secrets.token_hex(32))'`

---

## 🔍 Ferramentas Recomendadas

- **git-secrets**: Previne commit de secrets
- **TruffleHog**: Scan de histórico Git
- **GitGuardian**: Monitoramento contínuo
- **pre-commit**: Hooks automáticos

---

**Última atualização**: 2026-01-30
