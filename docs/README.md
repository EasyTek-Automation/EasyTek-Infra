# 📚 Volume de Documentação

Esta pasta contém a **documentação de procedimentos** que é montada como **volume externo** no container do webapp.

## 🔧 Como Funciona

O webapp lê os arquivos markdown desta pasta via volume Docker:
- **Host:** `./docs/procedures`
- **Container:** `/app/docs/procedures`
- **Variável de ambiente:** `DOCS_PROCEDURES_PATH=/app/docs/procedures`

## ✅ Vantagens desta Abordagem

- ✅ **Editar sem rebuild:** Modifique arquivos `.md` diretamente
- ✅ **Hot-reload:** Mudanças aparecem automaticamente na aplicação
- ✅ **Backup simples:** Basta copiar a pasta `procedures/`
- ✅ **Versionamento separado:** Pode usar git só para docs

## 📂 Estrutura de Pastas

```
docs/
├── README.md                    (este arquivo)
├── .gitignore                   (ignora conteúdo, versiona estrutura)
└── procedures/                  (conteúdo editável)
    ├── index.md                 (página inicial)
    ├── docs.yml                 (estrutura de navegação - opcional)
    └── AMG/                     (procedimentos por área)
        ├── LCT08/
        │   └── Calibracao/
        │       ├── FolgaFaca.md
        │       └── FolgaFaca02.md
        ├── LCT16/
        ├── Prensa_01/
        └── Revisoes/
```

## 📝 Como Editar Documentação

### Desenvolvimento Local (Windows)
```bash
# Editar arquivo diretamente
notepad "E:\Projetos Python\AMG_Infra\docs\procedures\AMG\LCT08\Calibracao\FolgaFaca.md"
```

### Servidor Linux (SSH)
```bash
# Conectar ao servidor
ssh usuario@servidor

# Editar arquivo
nano /caminho/AMG_Infra/docs/procedures/AMG/LCT08/Calibracao/FolgaFaca.md

# Salvar e sair (Ctrl+X, Y, Enter)
# A mudança aparece imediatamente na aplicação!
```

## 📋 Adicionar Novo Procedimento

1. **Criar arquivo markdown:**
   ```bash
   touch docs/procedures/AMG/NovoEquipamento/NovoProcedimento.md
   ```

2. **Editar com estrutura básica:**
   ```markdown
   # Nome do Procedimento

   ## Objetivo
   Descrição do objetivo...

   ## Materiais Necessários
   - Item 1
   - Item 2

   ## Procedimento
   1. Passo 1
   2. Passo 2
   ```

3. **Atualizar `docs.yml` (opcional):**
   ```yaml
   sections:
     - name: NovoEquipamento
       label: "Novo Equipamento"
       icon: "bi-gear"
       files:
         - path: "AMG/NovoEquipamento/NovoProcedimento.md"
           title: "Nome do Procedimento"
   ```

## 🔄 Sincronizar Documentação

### Copiar do Desenvolvimento para Produção
```bash
# Windows → Linux
scp -r "E:/Projetos Python/AMG_Infra/docs/procedures/*" usuario@servidor:/caminho/AMG_Infra/docs/procedures/

# Ou usar rsync (mais eficiente)
rsync -avz --delete "E:/Projetos Python/AMG_Infra/docs/procedures/" usuario@servidor:/caminho/AMG_Infra/docs/procedures/
```

### Backup Automático (Recomendado)
```bash
# No servidor, criar backup diário
0 2 * * * tar -czf /backup/docs-$(date +\%Y\%m\%d).tar.gz /caminho/AMG_Infra/docs/procedures/
```

## 🔒 Segurança

- Volume montado em **modo read-only** (`:ro`) para segurança
- Aplicação não pode modificar arquivos de documentação
- Apenas administradores com acesso SSH podem editar

## 🐛 Troubleshooting

### Documentação não aparece na aplicação

1. **Verificar se volume está montado:**
   ```bash
   docker exec -it <container-id> ls -la /app/docs/procedures
   ```

2. **Verificar variável de ambiente:**
   ```bash
   docker exec -it <container-id> env | grep DOCS
   # Deve mostrar: DOCS_PROCEDURES_PATH=/app/docs/procedures
   ```

3. **Verificar logs:**
   ```bash
   docker logs <container-id> | grep docs
   ```

### Mudanças não aparecem (cache)

- O sistema tem **hot-reload automático** baseado em `mtime`
- Mudanças devem aparecer em até 1 segundo
- Se não aparecer, reiniciar container: `docker restart <container-id>`

## 📖 Formato dos Arquivos

Os arquivos markdown suportam:
- ✅ Títulos (H1-H6)
- ✅ Listas (ordenadas e não ordenadas)
- ✅ Links e imagens
- ✅ Tabelas
- ✅ Blocos de código
- ✅ Alertas/avisos (via extensões)

Exemplo completo em: `procedures/AMG/LCT08/Calibracao/FolgaFaca.md`

---

**Última atualização:** 10/01/2026
**Mantido por:** Equipe Manutenção AMG
