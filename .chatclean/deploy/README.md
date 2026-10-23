# Deploy do ChatClean em produção

Produção numa máquina única na AWS, região São Paulo (sa-east-1), em `https://chat.chatclean.com.br`
(Epic E7, CCV2-12). A imagem é a **edição MIT**, sem a pasta `enterprise/`, que só pode rodar em
produção com licença paga do Chatwoot (CCV2-18).

## Arquivos

| Arquivo | Para quê |
|---|---|
| `docker-compose.production.yaml` | Caddy (HTTPS), rails, sidekiq, postgres (pgvector) e redis |
| `Caddyfile` | HTTPS automático para `CHATCLEAN_DOMAIN` e proxy para o rails |
| `env.production.example` | Lista das variáveis; no servidor elas vêm do SSM Parameter Store |
| `render-env.sh` | Gera o `.env` a partir de `/chatclean/production/*` no Parameter Store |
| `deploy.sh` | Banco + marca com a imagem nova, troca os containers, confere o `/health` e volta à imagem anterior se falhar |
| `release.sh` | Entrada do deploy no servidor: baixa a imagem do ECR, copia dela estes arquivos, instala o cron do backup, gera o `.env` e roda o `deploy.sh` |
| `backup-db.sh` | Backup diário do banco para o S3, com alerta por e-mail se falhar (CCV2-21) |
| `restore-check.sh` + `count-rows.sql` | Teste de restauração: restaura um dump num Postgres temporário e conta as linhas de cada tabela |
| `../bin/build-production-image` | Monta a imagem MIT no seu computador |
| `../../.github/workflows/chatclean-deploy.yml` | Monta a imagem, publica no ECR e chama o `release.sh` por SSM. Desligado até `CHATCLEAN_DEPLOY_ENABLED=true` |

## Como o deploy acontece

1. Um PR é mergeado na `main` (só com o "CI ok" verde).
2. O workflow entra na AWS por OIDC (sem chave fixa), monta a imagem sem `enterprise/`, confere e publica no ECR.
3. Pelo SSM Run Command (sem SSH), tira o `release.sh` da própria imagem e roda `release.sh <imagem>` em `/opt/chatclean`.
4. O `deploy.sh` roda `db:chatwoot_prepare` (cria o banco na primeira vez, migra nas seguintes) e `chatclean:branding` com a imagem nova. Se algo falhar, nada no ar muda.
5. Recria rails e sidekiq e espera o `/health`. Se não ficar saudável, volta para a imagem anterior.

Rollback não desfaz migrations: toda migration precisa funcionar com a versão anterior do código.
Cada deploy deixa o sistema fora do ar por alguns segundos (máquina única).

## Testar no seu computador

Monte a imagem e suba o pacote num projeto separado, em portas próprias. **Não use o nome de projeto
`chatclean`**: é o do ambiente de desenvolvimento, e o teste mexeria nos containers e no banco dele.

```sh
.chatclean/bin/build-production-image chatclean:local

mkdir -p /tmp/chatclean-prodtest && cp .chatclean/deploy/{docker-compose.production.yaml,Caddyfile,deploy.sh} /tmp/chatclean-prodtest/
# .env de teste: CHATCLEAN_DOMAIN=localhost, CHATCLEAN_HTTP_PORT=8080, CHATCLEAN_HTTPS_PORT=8443,
# FRONTEND_URL=https://localhost:8443, ACTIVE_STORAGE_SERVICE=local e senhas quaisquer.
cd /tmp/chatclean-prodtest && COMPOSE_PROJECT_NAME=chatclean-prodtest ./deploy.sh chatclean:local
```

Depois abra `https://localhost:8443` (certificado interno do Caddy). Para limpar:
`COMPOSE_PROJECT_NAME=chatclean-prodtest CHATCLEAN_IMAGE=chatclean:local docker compose -f docker-compose.production.yaml down -v`.

## Primeiro deploy (US 10 a US 13)

A infraestrutura é criada nas histórias CCV2-19 a CCV2-22, depois da aprovação dos créditos da AWS.
Antes de ligar o workflow:

1. A stack `chatclean-base` (`../infra/README.md`, CCV2-19): máquina com Docker, AWS CLI e SSM, IP
   fixo, firewall, ECR e a role de deploy. Os buckets (CCV2-21) e o SES (CCV2-22) vêm depois.
2. No Parameter Store, em `/chatclean/production/`, todas as variáveis do `env.production.example`
   (segredos como SecureString).
3. No GitHub, as variáveis `AWS_DEPLOY_ROLE_ARN` e `CHATCLEAN_INSTANCE_ID` (saídas da stack) e, por último,
   `CHATCLEAN_DEPLOY_ENABLED=true`.
4. No primeiro acesso, o sistema abre `/installation/onboarding` para criar o primeiro administrador e
   a conta. A tela já tem a marca ChatClean e não tem a caixa "receber novidades", que enviava ao
   Chatwoot o nome da empresa, o nome e o e-mail do administrador (CCV2-22).

## Backup e recuperação (CCV2-21)

| O quê | Como | Guarda |
|---|---|---|
| Banco | `backup-db.sh` às 03:00 de Brasília (cron instalado pelo `release.sh`) → `s3://chatclean-backups-<conta>/database/` | 30 dias |
| Disco inteiro (banco, Redis, certificados) | snapshot diário às 03:30 pelo Data Lifecycle Manager | 7 dias |
| Anexos | já ficam no S3 (`chatclean-attachments-<conta>`), fora da máquina | — |
| Filas do Sidekiq | Redis com `appendonly`, no disco | — |

Se o backup falhar, ou se o disco tiver menos de 10 GB livres, chega um e-mail do tópico `chatclean-alerts`.
O log fica em `/var/log/chatclean_backup.log`. Backup manual: `sudo /opt/chatclean/backup-db.sh`.

**Teste de restauração** (faça depois do primeiro deploy e a cada mês). Ele não toca em nenhum banco:

```sh
aws s3 ls s3://chatclean-backups-<conta>/database/ --profile ChatClean        # escolha o mais recente
aws s3 cp s3://chatclean-backups-<conta>/database/<arquivo> . --profile ChatClean
.chatclean/deploy/restore-check.sh <arquivo> > restaurado.txt
```

Na máquina (`aws ssm start-session`), conte as linhas do banco de produção e compare com `restaurado.txt`.
As tabelas do CRM (`crm_*`) entram na lista.

```sh
cd /opt/chatclean && sudo CHATCLEAN_IMAGE="$(cat .current-image)" docker compose -f docker-compose.production.yaml \
  exec -T postgres sh -c 'psql -At -F" " -U "$POSTGRES_USER" "$POSTGRES_DB"' < count-rows.sql
```

As contagens podem diferir nas tabelas que mudaram depois do horário do dump.

**Banco perdido ou corrompido, máquina boa:** com o dump mais recente em `/opt/chatclean`:

```sh
cd /opt/chatclean
export CHATCLEAN_IMAGE="$(cat .current-image)"
compose="docker compose -f docker-compose.production.yaml"
$compose stop rails sidekiq
$compose exec -T postgres sh -c 'dropdb -U "$POSTGRES_USER" "$POSTGRES_DB" && createdb -U "$POSTGRES_USER" "$POSTGRES_DB"'
gunzip -c <arquivo>.sql.gz | $compose exec -T postgres sh -c 'psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" "$POSTGRES_DB"'
$compose up -d
```

**Máquina perdida:** a partir do snapshot mais recente (perde no máximo um dia):

1. No console do EC2, em Snapshots, crie uma imagem (AMI) a partir do snapshot do disco.
2. `aws cloudformation deploy --stack-name chatclean-base --template-file .chatclean/infra/chatclean-base.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides AmiId=<ami>`
   cria uma máquina nova com esse disco. O Elastic IP passa para ela, então o DNS não muda. A máquina
   antiga fica (proteção e `Retain`) e precisa ser encerrada à mão.
3. Rode um deploy (workflow manual ou `release.sh`) para garantir a imagem atual.

## Validado localmente (23/10/2026)

Imagem MIT montada com `build-production-image`, pacote subido com `deploy.sh` em projeto separado:
HTTPS pelo Caddy (200 no `/health`), HTTP redirecionado para HTTPS, WebSocket do `/cable` (101),
logo da ChatClean servida, marca aplicada, `ChatwootApp.enterprise?` falso e sem `/app/enterprise`.
Rodado duas vezes: banco novo (schema + seeds) e banco existente (só migrations).
