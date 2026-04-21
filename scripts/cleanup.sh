#!/usr/bin/env bash
# cleanup.sh
# Remove build cache e imagens Docker nao usadas ha mais de N dias.
# Seguro: so remove imagens sem container associado (ativo ou parado).
#
# Uso:
#   ./scripts/cleanup.sh                # janela default de 7 dias
#   ./scripts/cleanup.sh --days 30      # manter imagens dos ultimos 30 dias
#   ./scripts/cleanup.sh --days 0       # remover TODAS imagens sem uso (agressivo)

set -euo pipefail

days=7

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d)
      days="$2"
      shift 2
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ERRO: argumento desconhecido: $1" >&2
      exit 1
      ;;
  esac
done

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
  echo "ERRO: --days deve ser um inteiro nao-negativo (recebido: $days)" >&2
  exit 1
fi

hours=$((days * 24))

echo "=== AMG Infra — Docker cleanup ==="
echo "Janela de retencao: $days dias ($hours horas)"
echo ""

echo "--- Estado antes ---"
docker system df
echo ""

echo "--- Fase 1: limpando build cache ---"
docker builder prune -af
echo ""

echo "--- Fase 2: removendo imagens sem uso criadas ha mais de $days dias ---"
if [[ "$days" -eq 0 ]]; then
  docker image prune -af
else
  docker image prune -af --filter "until=${hours}h"
fi
echo ""

echo "--- Estado depois ---"
docker system df
echo ""
echo "SUCESSO: Cleanup concluido."
