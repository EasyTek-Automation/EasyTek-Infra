# Volumes do ZPP Processor

Este diretório contém os volumes montados pelo serviço ZPP Processor.

## Estrutura

```
zpp/
├── input/      # Planilhas pendentes (colocar arquivos aqui)
├── output/     # Planilhas processadas (arquivamento automático)
└── logs/       # Logs detalhados (opcional)
```

## Uso

### Processamento Manual

1. Colocar arquivos `.xlsx` na pasta `input/`
2. Acessar interface web: `/maintenance/zpp-processor`
3. Clicar em "Processar Agora"
4. Aguardar conclusão (acompanhar progresso em tempo real)
5. Arquivos processados movidos automaticamente para `output/`

### Processamento Automático

O serviço verifica automaticamente a pasta `input/` a cada intervalo configurado (padrão: 60 minutos).

**Configurar intervalo**:
- Via interface web: `/maintenance/zpp-processor` → Configurações
- Via variável de ambiente: `ZPP_INTERVAL_MINUTES` em `.env.common`

**Ativar/Desativar**:
- Via interface web: Switch "Processamento Automático"
- Via variável de ambiente: `ZPP_AUTO_PROCESS=true/false`

## Tipos de Planilha Suportados

### ZPP PRD (Produção)
- Colunas obrigatórias: `Pto.Trab.`, `Kg.Proc.`, `HorasAct.`, `FIniNotif`, `FFinNotif`
- Collection destino: `ZPP_Producao_YYYY` (ano detectado automaticamente)

### ZPP Paradas
- Colunas obrigatórias: `Centro de trabalho`, `Início execução`, `Fim execução`, `Causa do desvio`, `Duration (min)`
- Collection destino: `ZPP_Paradas_YYYY`

## Fluxo de Processamento

1. ✅ **Detecção**: Tipo detectado automaticamente pelas colunas
2. ✅ **Limpeza**: Linhas totalizadoras removidas
3. ✅ **Filtragem**: Equipamentos EMBAL* removidos
4. ✅ **Normalização**: Colunas normalizadas (minúsculas, sem acentos)
5. ✅ **Upload**: Inserção em lotes no MongoDB (1000 registros/lote)
6. ✅ **Indexação**: Índices otimizados criados automaticamente
7. ✅ **Arquivamento**: Arquivo movido para `output/`
8. ✅ **Log**: Histórico registrado em MongoDB

## Boas Práticas

- **Nomenclatura**: Use nomes descritivos (ex: `zppprd_202601.xlsx`, `paradas_jan2026.xlsx`)
- **Organização**: Limpe periodicamente a pasta `output/` para liberar espaço
- **Backup**: Mantenha backup das planilhas originais antes de processar
- **Validação**: Verifique logs de processamento na interface web

## Troubleshooting

### Arquivo não é processado
- Verificar se está na pasta `input/`
- Verificar extensão (`.xlsx` apenas)
- Verificar se não é arquivo temporário (`~$...`)
- Ver logs do container: `docker logs zpp-processor`

### Processamento falha
- Verificar estrutura das colunas (deve seguir padrão SAP)
- Ver histórico de erros na interface web
- Consultar logs detalhados em `logs/`

### Duplicatas não inseridas
- Comportamento esperado! O sistema verifica duplicatas por:
  - **Produção**: Campo `Ordem` (unique)
  - **Paradas**: Combinação `centro_de_trabalho + inicio_execucao + inicio_real_hora + ordem`

## Permissões de Acesso

**Requisitos**:
- Perfil: `manutencao`
- Nível: 2+ (avançado)

**Acesso admin** (configurações):
- Perfil: `admin` ou `manutencao`
- Nível: 3 (admin)

## Suporte

Em caso de problemas:
1. Verificar logs do container
2. Consultar histórico de processamentos
3. Verificar conectividade com MongoDB
4. Contatar equipe de TI
