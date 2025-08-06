#!/bin/bash
set -e

# --- Validação ---
if [ -z "$1" ] || ! [[ "$1" =~ ^(local|dev|prod)$ ]]; then
  echo "ERRO: Forneça um ambiente válido (local, dev, prod) como primeiro argumento."
  echo "Uso: ./scripts/up.sh <ambiente>"
  exit 1
fi

ENV=$1
TAG=${2:-latest} # Usa o segundo argumento como tag, ou 'latest' como padrão
ENV_FILE="./environments/$ENV/.env"
OVERRIDE_FILE="./environments/$ENV/docker-compose.override.yml"

echo "INFO: Validando ambiente '$ENV'..."
if [ ! -f "$ENV_FILE" ]; then
    echo "ERRO: Arquivo de ambiente '$ENV_FILE' não encontrado."
    exit 1
fi

# --- Autenticação (A PARTE QUE FALTAVA) ---
if [[ "$ENV" != "local" ]]; then
  if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_PAT" ]; then
    echo "ERRO: Para ambientes 'dev' ou 'prod', as variáveis GITHUB_USER e GITHUB_PAT devem ser definidas."
    exit 1
  fi
  echo "INFO: Autenticando no ghcr.io..."
  echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
fi

# --- Execução ---
echo "INFO: Iniciando a infraestrutura de proxy para o ambiente '$ENV'..."
docker compose --env-file "$ENV_FILE" -f proxy-compose.yml up -d --wait

echo "INFO: Baixando (pull) as imagens da aplicação com a tag '$TAG'..."
export TAG # Exporta a variável TAG para que o docker compose a veja
docker compose --env-file "$ENV_FILE" -f docker-compose.yml -f "$OVERRIDE_FILE" pull

echo "INFO: Iniciando a aplicação principal para o ambiente '$ENV'..."
docker compose --env-file "$ENV_FILE" -f docker-compose.yml -f "$OVERRIDE_FILE" up -d

echo "SUCESSO: Ambiente '$ENV' iniciado com a tag '$TAG'."
