-- Linhas de cada tabela do banco (CCV2-21). Usado pelo restore-check.sh e para comparar com o
-- banco de origem: docker compose ... exec -T postgres sh -c 'psql -At -F" " -U "$POSTGRES_USER" "$POSTGRES_DB"' < count-rows.sql
SELECT table_name,
       (xpath('/row/n/text()', query_to_xml(format('SELECT count(*) AS n FROM %I.%I', table_schema, table_name), false, true, '')))[1]::text::bigint
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
