# ⚠️ Dívida Técnica - AMG_Infra

> **O que é Dívida Técnica?**
> Melhorias identificadas que **não são bugs críticos**, mas aumentam:
> - 🔒 Segurança
> - 📈 Robustez
> - 🧹 Manutenibilidade
> - 🛡️ Prevenção de problemas

---

## 📊 Status Geral

| Categoria | Total | 🔴 Alta | 🟡 Média | 🟢 Baixa | ✅ Concluído |
|-----------|-------|---------|----------|----------|--------------|
| **Configuração** | 8 | 5 | 2 | 1 | 0 |
| **Scripts** | 5 | 2 | 2 | 1 | 0 |
| **Docker/Compose** | 4 | 3 | 1 | 0 | 0 |
| **Documentação** | 4 | 2 | 2 | 0 | 0 |
| **TOTAL** | **21** | **12** | **7** | **2** | **0** |

---

## 📋 Lista de Débitos

### 🔴 Alta Prioridade

Impacto direto em funcionamento, prevenção de problemas e onboarding.

#### Configuração

1. **[Criar .env.example adequado](./configuration-improvements.md#1-env-example)**
   - Falta template completo com todas as variáveis obrigatórias
   - Causa: Novos devs não sabem quais variáveis são necessárias
   - **Impacto**: Dessincronização, falhas ao iniciar
   - **Esforço**: 1-2 horas

2. **[Remover paths hardcoded](./configuration-improvements.md#2-paths-hardcoded)**
   - Scripts assumem `C:\AMG-Infra\` e `E:\Projetos Python\AMG_Data\`
   - **Impacto**: Falha em outros ambientes/máquinas
   - **Esforço**: 2-3 horas

3. **[Documentar variáveis obrigatórias](./configuration-improvements.md#3-variaveis-obrigatorias)**
   - Não há lista de quais variáveis são obrigatórias
   - **Impacto**: Erros crípticos ao iniciar
   - **Esforço**: 1 hora

4. **[Separar credenciais por ambiente](./configuration-improvements.md#4-credenciais-ambiente)**
   - `.env.common` compartilhado entre local/dev/prod
   - **Impacto**: Risco de usar credenciais erradas
   - **Esforço**: 3-4 horas

5. **[Criar rede Docker automaticamente](./docker-improvements.md#1-rede-automatica)**
   - Scripts assumem que rede `easytek-net` já existe
   - **Impacto**: Falha ao iniciar em ambiente novo
   - **Esforço**: 1 hora

#### Scripts

6. **[Validar variáveis antes de iniciar](./scripts-improvements.md#1-validacao)**
   - Scripts não validam se variáveis obrigatórias estão definidas
   - **Impacto**: Erros tardios, difíceis de debugar
   - **Esforço**: 2-3 horas

7. **[Melhorar export de variáveis em Bash](./scripts-improvements.md#2-export-bash)**
   - `export $(grep ... | xargs)` quebra com valores contendo `=` ou espaços
   - **Impacto**: Variáveis não carregadas corretamente
   - **Esforço**: 1 hora

#### Docker/Compose

8. **[Remover user:root do Node-RED](./docker-improvements.md#2-node-red-root)**
   - Container rodando como root é risco de segurança
   - **Impacto**: Segurança comprometida
   - **Esforço**: 2-3 horas (investigar permissões)

9. **[Não expor MongoDB em prod](./docker-improvements.md#3-mongodb-exposto)**
   - Porta 27017 exposta sem autenticação adequada
   - **Impacto**: Acesso não autorizado ao banco
   - **Esforço**: 1 hora

10. **[Usar variáveis para portas](./docker-improvements.md#4-portas-variaveis)**
    - Portas hardcoded (8050, 5001, 1880)
    - **Impacto**: Conflitos de porta, difícil customizar
    - **Esforço**: 1-2 horas

#### Documentação

11. **[Criar SETUP.md](./documentation-improvements.md#1-setup)**
    - Não há guia de setup para novos desenvolvedores
    - **Impacto**: Onboarding lento, erros comuns
    - **Esforço**: 3-4 horas

12. **[Criar README.md na raiz](./documentation-improvements.md#2-readme)**
    - Não há README principal do projeto
    - **Impacto**: Ninguém sabe o que é o projeto
    - **Esforço**: 1-2 horas

---

### 🟡 Média Prioridade

Melhorias de código e manutenibilidade.

#### Scripts

13. **[Consolidar Bash/PowerShell](./scripts-improvements.md#3-consolidar)**
    - Mesma lógica duplicada em 2 linguagens
    - **Impacto**: Manutenção duplicada, bugs inconsistentes
    - **Esforço**: 1 dia (escolher uma linguagem)

14. **[Remover scripts diagnósticos duplicados](./scripts-improvements.md#4-diagnosticos-duplicados)**
    - `diagnose-docs.ps1` e `diagnose-docs-simple.ps1` são idênticos
    - **Impacto**: Confusão, manutenção duplicada
    - **Esforço**: 15 min

15. **[Melhorar tratamento de erros em wifi_monitor.py](./scripts-improvements.md#5-except-generico)**
    - `except:` genérico sem tipo específico
    - **Impacto**: Erros escondidos, difícil debugar
    - **Esforço**: 30 min

#### Configuração

16. **[Padronizar nomenclatura de .env](./configuration-improvements.md#5-nomenclatura)**
    - `.env`, `.env.common`, `.env.example` sem padrão claro
    - **Impacto**: Confusão sobre qual usar
    - **Esforço**: 2 horas

17. **[Documentar diferenças entre ambientes](./configuration-improvements.md#6-diff-ambientes)**
    - Não há tabela mostrando local vs dev vs prod
    - **Impacto**: Difícil entender o que muda
    - **Esforço**: 1 hora

#### Docker/Compose

18. **[Adicionar healthchecks](./docker-improvements.md#5-healthchecks)**
    - Containers sem healthcheck adequado
    - **Impacto**: Difícil saber se serviços estão realmente prontos
    - **Esforço**: 2 horas

#### Documentação

19. **[Criar TROUBLESHOOTING.md](./documentation-improvements.md#3-troubleshooting)**
    - Não há guia de problemas comuns
    - **Impacto**: Suporte repetitivo
    - **Esforço**: 2-3 horas

20. **[Comentar scripts adequadamente](./documentation-improvements.md#4-comentarios)**
    - Scripts com comentários superficiais
    - **Impacto**: Difícil entender lógica
    - **Esforço**: 2 horas

---

### 🟢 Baixa Prioridade

Nice-to-have, melhorias futuras.

#### Scripts

21. **[Criar testes para scripts](./scripts-improvements.md#6-testes)**
    - Scripts sem testes automatizados
    - **Impacto**: Regressões não detectadas
    - **Esforço**: 1-2 dias

#### Configuração

22. **[Usar Docker Secrets](./configuration-improvements.md#7-docker-secrets)**
    - Credenciais em .env ao invés de Docker Secrets
    - **Impacto**: Segurança poderia ser melhor
    - **Esforço**: 1 dia

---

## ✅ Concluídos

| # | Item | Data | Responsável | Commit/PR |
|---|------|------|-------------|-----------|
| - | *(nenhum ainda)* | - | - | - |

---

## 🎯 Meta

**Objetivo Q1 2026**:
- Zerar débitos de **Alta Prioridade** relacionados a configuração (4 itens)
- Criar SETUP.md e README.md (2 itens de documentação)

**Progresso**:
- 🔴 Alta: 0/12 concluído (0%)
- 🟡 Média: 0/7 concluído (0%)
- 🟢 Baixa: 0/2 concluído (0%)

---

## 📝 Como Usar

### Escolher um Item

1. Escolha da lista de prioridade desejada
2. Clique no link para ver **detalhes técnicos**
3. Implemente seguindo as sugestões

### Marcar como Concluído

1. Mova o item para seção **"Concluídos"**
2. Adicione data, responsável e link do commit/PR
3. Atualize a **tabela de Status Geral**

### Adicionar Novo Débito

1. Crie/edite arquivo específico em `technical-debt/`
2. Adicione entrada neste README na prioridade correta
3. Atualize a tabela de Status Geral

---

## 📚 Arquivos Detalhados

- **[configuration-improvements.md](./configuration-improvements.md)** - Melhorias de configuração
- **[scripts-improvements.md](./scripts-improvements.md)** - Melhorias em scripts
- **[docker-improvements.md](./docker-improvements.md)** - Melhorias Docker/Compose
- **[documentation-improvements.md](./documentation-improvements.md)** - Melhorias de documentação

---

**Última atualização**: 2026-01-30
**Status**: 📋 21 itens identificados, 0 resolvidos
