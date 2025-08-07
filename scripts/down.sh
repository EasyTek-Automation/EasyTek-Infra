#!/bin/bash
set -e

# Uso: ./down.sh <ambiente>
# Exemplo: ./down.sh dev

ENV=$1
ENV_FILE="./environments/$ENV/.env"
OVERRIDE_FILE="./environments/$ENV/docker-compose.override.yml"

echo "INFO: Parando o ambiente '$ENV' de forma controlada..."

docker compose --env-file $ENV_FILE -f "docker-compose.yml" -f $OVERRIDE_FILE down --remove-orphans
docker compose --env-file $ENV_FILE -f "proxy-compose.yml" down --remove-orphans

echo "SUCESSO: Ambiente '$ENV' parado."
