#!/usr/bin/env bash
# Teste de restauração (CCV2-21): restaura um dump do backup-db.sh num Postgres temporário
# (pgvector, como o de produção) e lista as linhas de cada tabela, para comparar com o banco
# de origem (count-rows.sql). Não toca em nenhum banco existente.
#
# Uso: restore-check.sh <chatclean_db_*.sql.gz>
set -euo pipefail

DUMP="${1:?uso: restore-check.sh <dump.sql.gz>}"
COUNT_SQL="$(dirname "$0")/count-rows.sql"
NAME="chatclean-restore-check-$$"

docker run -d --rm --name "$NAME" -e POSTGRES_PASSWORD=restore -e POSTGRES_DB=restore pgvector/pgvector:pg16 > /dev/null
trap 'docker stop "$NAME" > /dev/null' EXIT
# Por TCP: durante a inicialização o Postgres só escuta no socket, e depois reinicia.
until docker exec "$NAME" pg_isready -q -h 127.0.0.1 -U postgres -d restore; do sleep 1; done

gunzip -c "$DUMP" | docker exec -i "$NAME" psql -q -v ON_ERROR_STOP=1 -h 127.0.0.1 -U postgres -d restore > /dev/null
docker exec -i "$NAME" psql -At -F ' ' -h 127.0.0.1 -U postgres -d restore < "$COUNT_SQL"
