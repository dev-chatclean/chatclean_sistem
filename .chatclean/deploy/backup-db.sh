#!/usr/bin/env bash
# Backup diário do banco (CCV2-21). O release.sh instala o cron (03:00 de Brasília) em
# /etc/cron.d/chatclean-backup; também serve para um backup manual.
#
# Faz o pg_dump comprimido, envia para s3://chatclean-backups-<conta>/database/ (apagado
# depois de 30 dias pela regra do bucket) e remove o arquivo local. Se algo falhar, ou se o
# disco tiver menos de 10 GB livres, avisa no tópico chatclean-alerts (e-mail).
set -euo pipefail
cd "$(dirname "$0")"

REGION=sa-east-1
MIN_FREE_GB=10
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
TOPIC="arn:aws:sns:$REGION:$ACCOUNT:chatclean-alerts"
TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
DUMP="/tmp/chatclean_db_$TIMESTAMP.sql.gz"

alert() {
  echo "$(date -u +%FT%TZ) ERRO: $1" >&2
  aws sns publish --region "$REGION" --topic-arn "$TOPIC" \
    --subject "ChatClean: falha no backup do banco" --message "$1 (máquina $(hostname), $TIMESTAMP)" > /dev/null
}
trap 'rm -f "$DUMP"' EXIT
trap 'alert "o backup parou na linha $LINENO; veja /var/log/chatclean_backup.log"' ERR

free_gb="$(df --output=avail -BG /tmp | tail -1 | tr -dc '0-9')"
if [ "$free_gb" -lt "$MIN_FREE_GB" ]; then
  trap - ERR
  alert "backup não feito: só ${free_gb} GB livres no disco (mínimo ${MIN_FREE_GB} GB)"
  exit 1
fi

echo "$(date -u +%FT%TZ) Dump do banco"
# shellcheck disable=SC2016 # as variáveis são do container do postgres
CHATCLEAN_IMAGE="$(cat .current-image)" docker compose -f docker-compose.production.yaml exec -T postgres \
  sh -c 'pg_dump --no-owner --no-privileges -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$DUMP"

aws s3 cp --region "$REGION" --only-show-errors "$DUMP" "s3://chatclean-backups-$ACCOUNT/database/$(basename "$DUMP")"
echo "$(date -u +%FT%TZ) Backup enviado: $(basename "$DUMP") ($(du -h "$DUMP" | cut -f1))"
