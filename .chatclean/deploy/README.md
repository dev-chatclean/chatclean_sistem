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
| `release.sh` | Entrada do deploy no servidor: baixa a imagem do ECR, copia dela estes arquivos, gera o `.env` e roda o `deploy.sh` |
| `../bin/build-production-image` | Monta a imagem MIT no seu computador |
| `../../.github/workflows/chatclean-deploy.yml` | Monta a imagem, publica no ECR e chama o `release.sh` por SSM. Desligado até `CHATCLEAN_DEPLOY_ENABLED=true` |

## Como o deploy acontece

1. Um PR é mergeado na `main` (só com o "CI ok" verde).
2. O workflow entra na AWS por OIDC (sem chave fixa), monta a imagem sem `enterprise/`, confere e publica no ECR.
3. Pelo SSM Run Command (sem SSH), roda `/opt/chatclean/release.sh <imagem>` na máquina.
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

A infraestrutura (EC2, IP fixo, Security Group, IAM, ECR, buckets, SES) é criada nas histórias
CCV2-19 a CCV2-22, depois da aprovação dos créditos da AWS. Antes de ligar o workflow:

1. Na máquina: Docker, AWS CLI, SSM Agent, pasta `/opt/chatclean` com o `release.sh`.
2. No Parameter Store, em `/chatclean/production/`, todas as variáveis do `env.production.example`
   (segredos como SecureString).
3. No GitHub, as variáveis `AWS_DEPLOY_ROLE_ARN`, `CHATCLEAN_INSTANCE_ID` e, por último,
   `CHATCLEAN_DEPLOY_ENABLED=true`.
4. No primeiro acesso, o sistema abre `/installation/onboarding` para criar o primeiro administrador e
   a conta. A tela já tem a marca ChatClean e não tem a caixa "receber novidades", que enviava ao
   Chatwoot o nome da empresa, o nome e o e-mail do administrador (CCV2-22).

## Validado localmente (23/10/2026)

Imagem MIT montada com `build-production-image`, pacote subido com `deploy.sh` em projeto separado:
HTTPS pelo Caddy (200 no `/health`), HTTP redirecionado para HTTPS, WebSocket do `/cable` (101),
logo da ChatClean servida, marca aplicada, `ChatwootApp.enterprise?` falso e sem `/app/enterprise`.
Rodado duas vezes: banco novo (schema + seeds) e banco existente (só migrations).
