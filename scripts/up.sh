#!/bin/bash
set -e # Sai imediatamente se um comando falhar

# Uso: ./up.sh <ambiente> [tag]
# Exemplo: ./up.sh dev 0.1.0

ENV=$1
TAG=${2:-latest} # Usa o segundo argumento, ou 'latest' se não for fornecido

ENV_FILE="./environments/$ENV/.env"
OVERRIDE_FILE="./environments/$ENV/docker-compose.override.yml"

echo "INFO: Validando ambiente '$ENV'..."
if [ ! -f "$ENV_FILE" ]; then
    echo "ERRO: Arquivo de ambiente '$ENV_FILE' não encontrado."
    exit 1
fi

# Carrega as variáveis de ambiente para o script
export $(grep -v '^#' $ENV_FILE | xargs)

if [ "$ENV" != "local" ] && { [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_PAT" ]; }; then
    echo "ERRO: Para ambientes 'dev' ou 'prod', as variáveis GITHUB_USER e GITHUB_PAT devem ser definidas."
    exit 1
fi

echo "INFO: Iniciando a infraestrutura de proxy para o ambiente '$ENV'..."
docker compose --env-file $ENV_FILE -f "proxy-compose.yml" up -d --wait

if [ "$ENV" == "local" ]; then
    echo "INFO: Construindo e iniciando a aplicação para o ambiente local..."
    docker compose --env-file $ENV_FILE -f "docker-compose.yml" -f $OVERRIDE_FILE up -d --build
else
    echo "INFO: Autenticando no ghcr.io..."
    echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

    echo "INFO: Baixando (pull) as imagens com a tag '$TAG'..."
    TAG=$TAG docker compose --env-file $ENV_FILE -f "docker-compose.yml" -f $OVERRIDE_FILE pull

    echo "INFO: Iniciando a aplicação principal para o ambiente '$ENV'..."
    TAG=$TAG docker compose --env-file $ENV_FILE -f "docker-compose.yml" -f $OVERRIDE_FILE up -d
fi

echo "SUCESSO: Ambiente '$ENV' iniciado com a tag '$TAG'."
