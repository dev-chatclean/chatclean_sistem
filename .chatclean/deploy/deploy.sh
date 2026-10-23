#!/usr/bin/env bash
# Deploy do ChatClean na máquina de produção (CCV2-20). Roda em /opt/chatclean, chamado pelo
# GitHub Actions via SSM Run Command; também serve para um deploy manual.
#
# Uso: deploy.sh <imagem:tag>
#
# 1. Prepara o banco (cria na primeira vez, migra nas seguintes) e aplica a marca ChatClean
#    com a imagem nova. Se algo falhar aqui, os containers no ar não são tocados.
# 2. Recria rails e sidekiq com a imagem nova e espera o /health responder.
# 3. Se não ficar saudável, volta para a imagem anterior. Migrations não são desfeitas, por isso
#    toda migration precisa ser compatível com a versão anterior.
set -euo pipefail
cd "$(dirname "$0")"

NEW_IMAGE="${1:?uso: deploy.sh <imagem:tag>}"
PREVIOUS_IMAGE="$(cat .current-image 2>/dev/null || true)"

compose() {
  local image="$1"
  shift
  CHATCLEAN_IMAGE="$image" docker compose -f docker-compose.production.yaml "$@"
}

wait_healthy() {
  local container
  container="$(compose "$1" ps -q rails)"
  for _ in $(seq 1 30); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null)" = "healthy" ] && return 0
    sleep 5
  done
  return 1
}

# Imagem local (teste) não está num registry; em produção vem do ECR.
compose "$NEW_IMAGE" pull --quiet rails sidekiq 2>/dev/null || echo "Sem pull: usando a imagem local $NEW_IMAGE."

echo "==> Banco e marca com $NEW_IMAGE"
compose "$NEW_IMAGE" up -d --wait postgres redis
compose "$NEW_IMAGE" run --rm rails bundle exec rails db:chatwoot_prepare
compose "$NEW_IMAGE" run --rm rails bundle exec rails chatclean:branding

echo "==> Subindo $NEW_IMAGE"
compose "$NEW_IMAGE" up -d --remove-orphans

if wait_healthy "$NEW_IMAGE"; then
  echo "$NEW_IMAGE" > .current-image
  echo "==> Deploy concluído: $NEW_IMAGE"
  exit 0
fi

echo "==> $NEW_IMAGE não ficou saudável." >&2
if [ -n "$PREVIOUS_IMAGE" ]; then
  echo "==> Voltando para $PREVIOUS_IMAGE" >&2
  compose "$PREVIOUS_IMAGE" up -d rails sidekiq
fi
exit 1
