#!/usr/bin/env bash
# Gera o .env de produção a partir do SSM Parameter Store (CCV2-20). Cada parâmetro em
# /chatclean/production/<NOME> vira NOME=valor; os segredos são SecureString e saem
# decifrados só aqui, num arquivo legível apenas pelo root. A máquina lê pela IAM Role.
set -euo pipefail
cd "$(dirname "$0")"

PARAMETER_PATH="${CHATCLEAN_PARAMETER_PATH:-/chatclean/production}"
REGION="${AWS_REGION:-sa-east-1}"

umask 077
aws ssm get-parameters-by-path --region "$REGION" --path "$PARAMETER_PATH" --recursive \
  --with-decryption --query 'Parameters[].[Name,Value]' --output text |
  while IFS=$'\t' read -r name value; do
    printf '%s=%s\n' "${name##*/}" "$value"
  done > .env.tmp
mv .env.tmp .env
echo "==> .env gerado com $(wc -l < .env | tr -d ' ') variáveis de $PARAMETER_PATH"
