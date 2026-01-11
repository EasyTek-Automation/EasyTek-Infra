# ⚡ Quick Start - Volume de Documentação

## ✅ Status da Implementação

- ✅ `docker-compose.yml` configurado com volume
- ✅ Pasta `docs/procedures/` criada e populada
- ✅ Arquivos de documentação copiados (7 arquivos `.md`)
- ✅ `.gitignore` configurado (não versiona conteúdo)
- ✅ Guias criados: `README.md` e `DEPLOYMENT_DOCS.md`

---

## 🚀 Testar AGORA (Local)

```bash
# 1. Iniciar MongoDB (necessário)
net start MongoDB

# 2. Subir containers
cd "E:\Projetos Python\AMG_Infra"
docker-compose up -d

# 3. Ver logs
docker-compose logs -f webapp

# 4. Acessar
# http://localhost:8050
# Login → Ir em Manutenção/Procedimentos
```

---

## 📝 Editar Documentação (Teste)

```bash
# Editar um arquivo
notepad "E:\Projetos Python\AMG_Infra\docs\procedures\AMG\LCT08\Calibracao\FolgaFaca.md"

# Adicionar linha no final:
## Teste de Hot-Reload
Esta linha foi adicionada para testar!

# Salvar e recarregar página no navegador
# Deve aparecer IMEDIATAMENTE (sem restart)
```

---

## 🌍 Deploy Produção

### Opção A: Git Push (Recomendado)

```bash
# 1. Commitar mudanças
cd "E:\Projetos Python\AMG_Infra"
git add docker-compose.yml docs/.gitignore docs/README.md docs/procedures/.gitkeep DEPLOYMENT_DOCS.md
git commit -m "feat(infra): Adicionar volume externo para documentação"
git push origin main

# 2. No servidor, pull e copiar docs
ssh usuario@servidor
cd /caminho/easytek-infra
git pull origin main

# 3. Copiar documentação (do Windows)
scp -r "E:/Projetos Python/AMG_Infra/docs/procedures/*" usuario@servidor:/caminho/easytek-infra/docs/procedures/

# 4. Deploy
docker-compose pull
docker-compose up -d
```

### Opção B: Deploy Direto

```bash
# Do Windows, copiar tudo para servidor via SCP
scp -r "E:/Projetos Python/AMG_Infra/docker-compose.yml" usuario@servidor:/caminho/easytek-infra/
scp -r "E:/Projetos Python/AMG_Infra/docs" usuario@servidor:/caminho/easytek-infra/

# No servidor
docker-compose pull
docker-compose up -d
```

---

## 🐛 Troubleshooting Rápido

### Documentos não aparecem?

```bash
# Verificar volume montado
docker-compose exec webapp ls /app/docs/procedures/

# Verificar variável de ambiente
docker-compose exec webapp env | grep DOCS

# Ver logs
docker-compose logs webapp | grep docs
```

### Mudanças não aparecem?

```bash
# Reiniciar webapp
docker-compose restart webapp

# Ou rebuild completo
docker-compose down
docker-compose up -d
```

---

## 📚 Documentação Completa

- **Guia de Uso:** `docs/README.md`
- **Guia de Deploy:** `DEPLOYMENT_DOCS.md`
- **Docker Compose:** `docker-compose.yml`

---

## 🎯 Próximo Passo

➡️ **TESTE AGORA:** Suba os containers e edite um arquivo `.md` para ver o hot-reload funcionando!

```bash
docker-compose up -d
notepad "docs\procedures\AMG\LCT08\Calibracao\FolgaFaca.md"
# (fazer mudança e salvar)
# (recarregar página no navegador)
```

---

✅ **Implementação 100% completa!**
