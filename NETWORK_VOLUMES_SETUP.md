# Configuração de Volumes de Rede para ZPP Processor

## 📋 Visão Geral

Este documento descreve a migração dos volumes do ZPP Processor de diretórios locais para volumes de rede CIFS/SMB.

### Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Localização** | `./volumes/zpp/*` | `\\sumare\Comum\manutencao\AMG EASYTEK DATA\*` |
| **Acesso** | Apenas no host Docker | Toda a rede |
| **Backup** | Manual | Centralizado no servidor |
| **Escalabilidade** | Um container | Múltiplos containers |

---

## 🗂️ Estrutura de Rede

```
\\sumare\Comum\manutencao\AMG EASYTEK DATA\
├── input\     # Planilhas pendentes (.xlsx)
├── output\    # Planilhas processadas (arquivo automático)
└── logs\      # Logs detalhados (opcional)
```

---

## ✅ Pré-requisitos

- [x] Compartilhamento `\\sumare\Comum\manutencao\AMG EASYTEK DATA` existe
- [x] Usuário Windows tem permissão de leitura/escrita
- [x] Docker Desktop roda com esse usuário
- [ ] Estrutura de diretórios criada (input, output, logs)
- [ ] Credenciais configuradas no `.env.common`

---

## 🚀 Guia de Implantação

### Passo 1: Executar Script de Migração

```powershell
cd E:\Projetos Python\AMG_Infra\scripts
.\migrate-zpp-to-network.ps1
```

**O que o script faz:**
1. Valida acesso à rede
2. Cria diretórios (input, output, logs)
3. Copia arquivos existentes para a rede
4. Exibe resumo da migração

---

### Passo 2: Configurar Credenciais

Edite o arquivo `.env.common`:

```bash
# Abrir com editor de texto
notepad .env.common
```

Localize a seção **Configurações de Volumes de Rede ZPP** e configure:

```bash
# --- Configurações de Volumes de Rede ZPP ---
ZPP_NETWORK_USER=seu_usuario_windows
ZPP_NETWORK_PASSWORD=sua_senha_windows
```

**Importante:**
- Use o **mesmo usuário** que roda o Docker Desktop
- Certifique-se de que a senha está **correta**
- **Não compartilhe** este arquivo (já está no .gitignore)

---

### Passo 3: Recriar Container

```bash
# Parar todos os serviços
docker-compose down

# Subir novamente (vai recriar volumes)
docker-compose up -d

# Acompanhar logs do ZPP Processor
docker logs -f zpp-processor
```

**Saída esperada:**
```
[Scheduler] Conectado ao MongoDB
[OK] Diretório: /data/input
[OK] Diretório: /data/output
[OK] Diretório: /data/logs
MongoDB: Cluster-EasyTek ✓
Scheduler: Iniciado ✓
ZPP PROCESSOR - Pronto
Porta: 5002
```

---

### Passo 4: Validar Montagem

```bash
# Verificar se volumes foram montados corretamente
docker exec zpp-processor ls -la /data/input
docker exec zpp-processor ls -la /data/output
docker exec zpp-processor ls -la /data/logs

# Testar escrita
docker exec zpp-processor touch /data/logs/test-$(date +%Y%m%d).txt

# Verificar no Windows Explorer se arquivo apareceu
# \\sumare\Comum\manutencao\AMG EASYTEK DATA\logs\test-YYYYMMDD.txt
```

---

### Passo 5: Testar Processamento

#### Opção A: Via Interface Web

1. Acesse: http://localhost:8050/maintenance/zpp-processor
2. Coloque um arquivo `.xlsx` em `\\sumare\Comum\manutencao\AMG EASYTEK DATA\input\`
3. Clique em **"Processar Agora"**
4. Aguarde processamento (acompanhe na tabela de histórico)
5. Verifique se arquivo foi movido para `output\`

#### Opção B: Via API

```bash
# Verificar arquivos pendentes
curl http://localhost:5002/api/zpp/files/input

# Iniciar processamento
curl -X POST http://localhost:5002/api/zpp/process \
  -H "Content-Type: application/json" \
  -d '{"triggered_by": "admin@test"}'

# Consultar status (substitua JOB_ID)
curl http://localhost:5002/api/zpp/status/JOB_ID
```

---

## 🔍 Troubleshooting

### Erro: "Cannot mount CIFS volume"

**Causa**: Credenciais incorretas ou permissões insuficientes.

**Solução**:
```bash
# 1. Verificar acesso manual no Windows
cd "\\sumare\Comum\manutencao\AMG EASYTEK DATA"

# 2. Verificar credenciais no .env.common
cat .env.common | grep ZPP_NETWORK

# 3. Recriar volumes
docker-compose down
docker volume rm amg-infra_zpp-input amg-infra_zpp-output amg-infra_zpp-logs
docker-compose up -d zpp-processor
```

---

### Erro: "Permission denied" ao escrever em /data/input

**Causa**: Permissões CIFS incorretas.

**Solução**:

Edite `docker-compose.yml` e ajuste as permissões:

```yaml
o: username=${ZPP_NETWORK_USER},password=${ZPP_NETWORK_PASSWORD},uid=0,gid=0,file_mode=0777,dir_mode=0777
```

Depois recrie:
```bash
docker-compose down
docker-compose up -d zpp-processor
```

---

### Arquivos não aparecem na rede

**Causa**: Volume não montado ou path incorreto.

**Solução**:
```bash
# Verificar se volume foi criado
docker volume ls | grep zpp

# Inspecionar configuração do volume
docker volume inspect amg-infra_zpp-input

# Verificar logs do container
docker logs zpp-processor | grep -i error
```

---

### Performance lenta ao processar

**Causa**: Latência de rede.

**Solução**:
- Aumentar `BATCH_SIZE` no `.env.common` (ex: 2000)
- Verificar velocidade da rede (ping, largura de banda)
- Considerar processar em horários de baixo tráfego

---

## 📊 Monitoramento

### Verificar espaço usado na rede

```powershell
# No Windows Explorer
\\sumare\Comum\manutencao\AMG EASYTEK DATA
# Clicar com botão direito → Propriedades
```

### Listar arquivos via Docker

```bash
# Arquivos pendentes
docker exec zpp-processor find /data/input -name "*.xlsx" -type f

# Arquivos processados
docker exec zpp-processor find /data/output -name "*.xlsx" -type f | wc -l

# Logs recentes
docker exec zpp-processor ls -lht /data/logs | head -10
```

---

## 🔒 Segurança

### Boas Práticas

✅ **Credenciais**:
- `.env.common` está no `.gitignore`
- Nunca commitar credenciais no Git
- Usar usuário com permissões mínimas necessárias

✅ **Permissões de Rede**:
- Limitar acesso ao compartilhamento apenas para usuários autorizados
- Considerar criar usuário específico para Docker (ex: `svc_docker`)

✅ **Auditoria**:
- Habilitar logs de acesso no servidor de arquivos
- Monitorar atividades suspeitas

---

## 🔄 Rollback (Voltar para Volumes Locais)

Se precisar reverter para volumes locais:

```bash
# 1. Parar serviços
docker-compose down

# 2. Editar docker-compose.yml
# Substituir:
#   - zpp-input:/data/input:rw
# Por:
#   - ./volumes/zpp/input:/data/input:rw

# 3. Remover seção de volumes CIFS

# 4. Copiar arquivos da rede de volta
robocopy "\\sumare\Comum\manutencao\AMG EASYTEK DATA\output" volumes\zpp\output /E

# 5. Subir novamente
docker-compose up -d
```

---

## 📈 Benefícios da Configuração

| Benefício | Descrição |
|-----------|-----------|
| **Acesso Centralizado** | Qualquer usuário autorizado pode colocar arquivos para processar |
| **Backup Automático** | Se o servidor tem backup, os dados ZPP também têm |
| **Escalabilidade** | Múltiplos containers podem acessar o mesmo volume |
| **Auditoria** | Logs de acesso do servidor de arquivos |
| **Redundância** | Servidor de arquivos geralmente tem RAID |

---

## 📞 Suporte

**Problemas com volumes de rede:**
- Verificar conectividade: `ping sumare`
- Verificar acesso: `\\sumare\Comum\manutencao\AMG EASYTEK DATA`
- Consultar logs: `docker logs zpp-processor`

**Documentação:**
- ZPP Processor: `../AMG_Data/zpp-processor/README.md`
- Docker Volumes: https://docs.docker.com/storage/volumes/

---

**Última atualização**: 2026-02-13
