#!/bin/sh
# FA 2.3 (CCV2-2): um PR do ChatClean não pode criar models direto na raiz de app/models/.
# Models do CRM ficam em app/models/crm/ (namespace Crm::). PRs que trazem o upstream
# (head `develop` ou `sync/upstream-*`) ficam de fora, porque carregam models novos do Chatwoot.
# Uso: check-crm-namespace.sh <base-ref> [head-branch]
set -e

base="$1"
head_branch="${2:-}"

case "$head_branch" in
  develop|sync/upstream-*)
    echo "PR de sincronização com o upstream ($head_branch): check de namespace ignorado."
    exit 0
    ;;
esac

violations=$(git diff --name-only --diff-filter=A "$base"...HEAD -- 'app/models/*.rb' | grep -E '^app/models/[^/]+\.rb$' || true)

if [ -n "$violations" ]; then
  for file in $violations; do
    echo "::error file=$file::Model novo na raiz de app/models/. Models do CRM ficam em app/models/crm/ (namespace Crm::)."
  done
  exit 1
fi

echo "Namespace OK: nenhum model novo na raiz de app/models/."
