#!/usr/bin/env bash
# Ponto de entrada do deploy no servidor (CCV2-20), chamado pelo GitHub Actions via
# SSM Run Command. Baixa a imagem do ECR, copia dela os arquivos de deploy desta pasta,
# gera o .env a partir do Parameter Store e roda o deploy.sh.
#
# Uso: release.sh <conta>.dkr.ecr.sa-east-1.amazonaws.com/chatclean:<sha>
set -euo pipefail

IMAGE="${1:?uso: release.sh <imagem:tag>}"
DEPLOY_DIR="${CHATCLEAN_DEPLOY_DIR:-/opt/chatclean}"
cd "$DEPLOY_DIR"

aws ecr get-login-password --region sa-east-1 | docker login --username AWS --password-stdin "${IMAGE%%/*}"
docker pull --quiet "$IMAGE"

for file in docker-compose.production.yaml Caddyfile deploy.sh render-env.sh release.sh; do
  docker run --rm --entrypoint cat "$IMAGE" "/app/.chatclean/deploy/$file" > "$file.new"
  mv "$file.new" "$file"
done
chmod +x deploy.sh render-env.sh release.sh

./render-env.sh
./deploy.sh "$IMAGE"
