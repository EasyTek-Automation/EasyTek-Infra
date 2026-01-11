# 🚀 Guia de Deploy - Volume de Documentação

Este guia detalha como fazer o deploy da aplicação com o **volume de documentação** configurado.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Acesso SSH ao servidor
- Repositório `easytek-infra` clonado no servidor

---

## 🔧 Passo 1: Preparar Servidor

### 1.1 Clonar Repositório (se ainda não tiver)

```bash
# No servidor
cd /opt  # ou outro diretório de sua escolha
git clone https://github.com/easytek-automation/easytek-infra.git
cd easytek-infra
```

### 1.2 Criar Estrutura de Pastas

```bash
# Criar pasta para documentação
mkdir -p docs/procedures

# Verificar estrutura
ls -la docs/
# Deve mostrar: procedures/ e README.md
```

---

## 📦 Passo 2: Copiar Documentação

### Opção A: Via SCP (de desenvolvimento para produção)

```bash
# Na máquina de desenvolvimento (Windows)
scp -r "E:/Projetos Python/AMG_Infra/docs/procedures/*" usuario@servidor:/opt/easytek-infra/docs/procedures/
```

### Opção B: Via Git (se versionado separadamente)

```bash
# No servidor
cd /opt/easytek-infra/docs/procedures
git clone https://github.com/sua-org/documentacao-amg.git .
```

### Opção C: Copiar Manualmente

```bash
# No servidor, criar arquivo de exemplo
cat > docs/procedures/index.md << 'EOF'
# Procedimentos AMG

Bem-vindo ao sistema de documentação!

## Categorias

- [LCT08](AMG/LCT08/)
- [LCT16](AMG/LCT16/)
- [Prensa 01](AMG/Prensa_01/)
EOF
```

---

## ⚙️ Passo 3: Configurar Ambiente

### 3.1 Verificar `.env.common`

```bash
# Editar arquivo de ambiente
nano .env.common

# Adicionar (se não existir):
DOCS_PROCEDURES_PATH=/app/docs/procedures
```

### 3.2 Verificar `docker-compose.yml`

```bash
# Verificar se webapp tem volume configurado
grep -A 5 "volumes:" docker-compose.yml

# Deve mostrar:
#     volumes:
#       - ./docs/procedures:/app/docs/procedures:ro
```

---

## 🚢 Passo 4: Deploy

### 4.1 Fazer Login no Registry

```bash
# Autenticar no GitHub Container Registry
echo $GITHUB_PAT | docker login ghcr.io -u $GITHUB_USER --password-stdin
```

### 4.2 Pull das Imagens

```bash
# Pull da versão mais recente
docker-compose pull
```

### 4.3 Iniciar Serviços

```bash
# Parar containers antigos (se existirem)
docker-compose down

# Iniciar com nova configuração
docker-compose up -d

# Verificar logs
docker-compose logs -f webapp
```

---

## ✅ Passo 5: Verificar Funcionamento

### 5.1 Verificar Volume Montado

```bash
# Entrar no container
docker-compose exec webapp bash

# Verificar se pasta existe
ls -la /app/docs/procedures/

# Verificar variável de ambiente
echo $DOCS_PROCEDURES_PATH

# Sair do container
exit
```

### 5.2 Testar na Aplicação

1. Acessar aplicação: `http://servidor:8050`
2. Fazer login
3. Navegar para página de **Procedimentos** ou **Manutenção**
4. Verificar se documentos aparecem

### 5.3 Verificar Logs

```bash
# Ver logs do webapp
docker-compose logs webapp | grep -i docs

# Deve mostrar algo como:
# "docs.yml carregado de /app/docs/procedures/docs.yml"
# ou
# "Estrutura carregada via scan automático"
```

---

## 🔄 Passo 6: Atualizar Documentação

### 6.1 Editar Arquivo Existente

```bash
# No servidor
nano docs/procedures/AMG/LCT08/Calibracao/FolgaFaca.md

# Fazer mudanças...
# Salvar (Ctrl+X, Y, Enter)

# A mudança aparece IMEDIATAMENTE na aplicação!
```

### 6.2 Adicionar Novo Arquivo

```bash
# Criar novo procedimento
mkdir -p docs/procedures/AMG/NovoEquipamento
nano docs/procedures/AMG/NovoEquipamento/NovoProcedimento.md

# Adicionar conteúdo:
# Nome do Procedimento
## Objetivo
...

# Salvar e verificar na aplicação
```

### 6.3 Atualizar Estrutura de Navegação (Opcional)

```bash
# Editar docs.yml
nano docs/procedures/docs.yml

# Adicionar nova seção:
sections:
  - name: NovoEquipamento
    label: "Novo Equipamento"
    icon: "bi-gear"
    files:
      - path: "AMG/NovoEquipamento/NovoProcedimento.md"
        title: "Novo Procedimento"

# Salvar - mudanças aparecem automaticamente!
```

---

## 🐛 Troubleshooting

### Problema: Documentação não aparece

**Causa 1: Volume não montado**
```bash
# Verificar
docker-compose exec webapp ls -la /app/docs/procedures/

# Se vazio, verificar docker-compose.yml
```

**Causa 2: Permissões**
```bash
# No servidor, ajustar permissões
chmod -R 755 docs/procedures/
chown -R 1000:1000 docs/procedures/  # UID do usuário no container
```

**Causa 3: Variável de ambiente não definida**
```bash
# Verificar
docker-compose exec webapp env | grep DOCS

# Se não aparecer, adicionar em .env.common ou docker-compose.yml
```

### Problema: Mudanças não aparecem

**Solução 1: Verificar hot-reload**
```bash
# Ver logs
docker-compose logs -f webapp | grep docs
```

**Solução 2: Reiniciar container**
```bash
docker-compose restart webapp
```

### Problema: Erro de permissão ao editar

**Solução: Ajustar proprietário**
```bash
# No servidor
sudo chown -R $USER:$USER docs/procedures/
```

---

## 📊 Monitoramento

### Verificar Uso de Espaço

```bash
# Tamanho da documentação
du -sh docs/procedures/

# Detalhes por pasta
du -h --max-depth=2 docs/procedures/
```

### Backup Automático

```bash
# Criar script de backup
cat > /usr/local/bin/backup-docs.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/docs"
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/docs-$DATE.tar.gz /opt/easytek-infra/docs/procedures/
# Manter apenas últimos 7 backups
ls -t $BACKUP_DIR/docs-*.tar.gz | tail -n +8 | xargs -r rm
EOF

# Tornar executável
chmod +x /usr/local/bin/backup-docs.sh

# Adicionar ao cron (backup diário às 2h)
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-docs.sh") | crontab -
```

---

## 🔐 Segurança

### Read-Only Mount

O volume é montado como **read-only** (`:ro`) no container:
- ✅ Aplicação não pode modificar arquivos
- ✅ Proteção contra malware/scripts maliciosos
- ✅ Apenas admins com SSH podem editar

### Permissões Recomendadas

```bash
# Proprietário: usuário que roda docker-compose
chown -R $USER:$USER docs/procedures/

# Permissões: leitura para todos, escrita apenas para proprietário
chmod -R 644 docs/procedures/**/*.md
chmod -R 755 docs/procedures/**/
```

---

## 📝 Checklist de Deploy

- [ ] Estrutura de pastas criada (`docs/procedures/`)
- [ ] Documentação copiada para o servidor
- [ ] `docker-compose.yml` configurado com volume
- [ ] Variável `DOCS_PROCEDURES_PATH` definida
- [ ] Pull das imagens feito
- [ ] Containers iniciados com `docker-compose up -d`
- [ ] Volume verificado dentro do container
- [ ] Documentação aparecendo na aplicação
- [ ] Teste de edição realizado (hot-reload funcionando)
- [ ] Backup automático configurado

---

## 📞 Suporte

- **Documentação do projeto:** `/docs/README.md`
- **Logs:** `docker-compose logs webapp`
- **Issues:** GitHub Issues do projeto

---

**Última atualização:** 10/01/2026
