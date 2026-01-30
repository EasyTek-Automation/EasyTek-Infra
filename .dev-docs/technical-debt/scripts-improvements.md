# 🔧 Melhorias - Scripts

Melhorias identificadas nos scripts de automação.

---

## 🔴 Alta Prioridade

### 1. Validar Variáveis Antes de Iniciar {#1-validacao}

**Problema**: Scripts não verificam se variáveis obrigatórias estão definidas

**Arquivo**: `scripts/up.sh`, `scripts/up.ps1`

**Solução**:
```powershell
# up.ps1 - Adicionar validação
function Test-RequiredVars {
    $required = @('MONGO_URI', 'DB_NAME', 'SECRET_KEY', 'GATEWAY_URL')
    $missing = $required | Where-Object { -not (Test-Path env:$_) }

    if ($missing) {
        Write-Error "Variáveis faltando: $($missing -join ', ')"
        exit 1
    }
}
Test-RequiredVars
```

**Estimativa**: 2-3 horas

---

### 2. Melhorar Export de Variáveis em Bash {#2-export-bash}

**Problema**: `export $(grep ... | xargs)` quebra com valores contendo `=` ou espaços

**Arquivo**: `scripts/up.sh:20`

**Atual**:
```bash
export $(grep -v '^#' $ENV_FILE | xargs)  # ❌ Quebra facilmente
```

**Solução**:
```bash
# Usar set -a/set +a (mais seguro)
set -a
source $ENV_FILE
set +a
```

**Estimativa**: 1 hora

---

## 🟡 Média Prioridade

### 3. Consolidar Bash/PowerShell {#3-consolidar}

**Problema**: Mesma lógica em 2 linguagens (manutenção duplicada)

**Arquivos**:
- `scripts/up.sh` (44 linhas) vs `scripts/up.ps1` (62 linhas)
- `scripts/down.sh` (16 linhas) vs `scripts/down.ps1` (55 linhas)

**Opções**:
1. **Manter apenas PowerShell** (funciona em Linux com PowerShell Core)
2. **Manter apenas Bash** (funciona em Windows com WSL/Git Bash)
3. **Usar Python** (multiplataforma nativo)

**Recomendação**: PowerShell Core (já instalado no Windows, fácil instalar no Linux)

**Estimativa**: 1 dia

---

### 4. Remover Scripts Duplicados {#4-diagnosticos-duplicados}

**Problema**: `diagnose-docs.ps1` e `diagnose-docs-simple.ps1` são praticamente idênticos

**Solução**: Manter apenas um, adicionar flag `--simple` se necessário

**Estimativa**: 15 min

---

### 5. Melhorar Exceções em wifi_monitor.py {#5-except-generico}

**Problema**: `except:` genérico sem tipo

**Arquivo**: `scripts/wifi_monitor.py:51-53`

**Atual**:
```python
except:
    logging.error("Erro ao desconectar WiFi")
    return False
```

**Solução**:
```python
except subprocess.CalledProcessError as e:
    logging.error(f"Erro ao desconectar WiFi: {e}")
    return False
except Exception as e:
    logging.error(f"Erro inesperado: {e}")
    raise  # Re-raise para não esconder bugs
```

**Estimativa**: 30 min

---

## 🟢 Baixa Prioridade

### 6. Criar Testes para Scripts {#6-testes}

**Problema**: Scripts sem testes automatizados

**Solução**: Usar `pester` (PowerShell) ou `bats` (Bash)

**Exemplo**:
```powershell
# tests/up.Tests.ps1
Describe "up.ps1" {
    It "Valida ambiente corretamente" {
        { ./scripts/up.ps1 -env invalid } | Should -Throw
    }

    It "Requer .env file" {
        Remove-Item .env -ErrorAction SilentlyContinue
        { ./scripts/up.ps1 -env local } | Should -Throw
    }
}
```

**Estimativa**: 1-2 dias

---

**Última atualização**: 2026-01-30
