# ChatClean — ambiente de desenvolvimento

Fork do [Chatwoot](https://github.com/chatwoot/chatwoot). Tudo que é específico do ChatClean
fica em caminhos que não existem no upstream (`.chatclean/`, `docker-compose.override.yaml`),
para que os merges do Chatwoot não gerem conflito.

## Primeira configuração

```sh
git clone https://github.com/dev-chatclean/chatclean_sistem.git
cd chatclean_sistem

nvm install && corepack enable      # Node 24 (.nvmrc) + pnpm 10.2.0 (packageManager)
pnpm install                        # node_modules no host: hooks (lint-staged) e Vitest
.chatclean/bin/setup-git            # upstream (push bloqueado) + hooks ChatClean

cp .env.example .env
# no .env: SECRET_KEY_BASE=$(openssl rand -hex 64), FRONTEND_URL=http://localhost:3000, SMTP_ADDRESS=mailhog
# não defina POSTGRES_DATABASE (dev e teste passariam a usar o mesmo banco)

docker compose build base && docker compose build
docker compose up -d --wait postgres redis
docker compose run --rm --no-deps rails bundle exec rails db:chatwoot_prepare   # schema + seed
docker compose up -d
```

- App: http://localhost:3000 — `john@acme.inc` / `Password1!` (definido em `db/seeds.rb`)
- Mailhog: http://localhost:8025
- Todas as portas ficam presas a `127.0.0.1`.

Ruby 3.4.4, ImageMagick e libvips vêm na imagem Docker. Rodar Ruby nativo no macOS não é suportado
aqui; se gems nativas falharem, use o Docker.

## Testes e linters

```sh
pnpm test                                                        # Vitest
pnpm eslint
docker run --rm -v "$PWD":/workspace -w /workspace chatclean-rails:development bundle exec rubocop --parallel

# RSpec: compile os assets de teste uma vez e desligue o auto-build
docker compose run --rm --no-deps -e RAILS_ENV=test -e NODE_OPTIONS=--max-old-space-size=6144 vite bin/vite build --mode=test
docker compose run --rm -e RAILS_ENV=test -e VITE_RUBY_AUTO_BUILD=false -v /dev/null:/app/.env \
  rails sh -c 'unset FRONTEND_URL DISABLE_ENTERPRISE; bundle exec rspec [spec/caminho_spec.rb]'
```

O RSpec roda com o Enterprise ligado, como o CI, para a regressão do upstream valer; por isso o `unset DISABLE_ENTERPRISE` (ver "Marca ChatClean e edição MIT").

O CI roda sem `.env`, e alguns specs dependem de `FRONTEND_URL` estar **ausente**:
- com o valor de dev, o `slack_uploads_controller_spec` falha com `UnsafeRedirectError`;
- com o valor vazio, os specs de SAML e do `devise_mailer` perdem o default `http://localhost:3000`.

Por isso o comando apaga a variável e mascara o `.env` (que o dotenv recarregaria) só nesse container.

Por que desligar o auto-build: o `docker/entrypoints/rails.sh` apaga `tmp/cache` a cada start, e é ali que
o `vite_ruby` guarda o registro do último build. Com o auto-build ligado, os specs que renderizam views
recompilam todo o frontend, e no container essa compilação estoura a memória padrão do Node.

O pre-commit do Chatwoot tenta rodar `bundle exec rubocop` no host. Sem Ruby 3.4.4 no host, ele falha
silenciosamente e os arquivos `.rb` **não** são lintados no commit. Rode o comando acima antes do push.

RuboCop não deve rodar com o código em `/app`, como faz o `docker compose run rails`: as regras do
rubocop-rails usam padrões como `**/app/**/*.rb`, e então todo arquivo passa a contar como `app/`.
Isso gera falsos positivos em `script/` e `spec/support/`.

Se o build de assets do Vite estourar a memória (`JavaScript heap out of memory`), passe
`-e NODE_OPTIONS=--max-old-space-size=6144`.

## Marca ChatClean e edição MIT

O código de `enterprise/` tem licença própria (`enterprise/LICENSE`): **só pode rodar em produção com assinatura Chatwoot Enterprise**. A ChatClean V2 roda como edição MIT (decisão do PO, CCV2-18).

**Ambiente local**
- `DISABLE_ENTERPRISE=true` no rails e no sidekiq (`docker-compose.override.yaml`).
- O `config/application.rb` ainda carrega o código, mas as extensões Enterprise ficam desligadas. Entre elas está o job que devolve nome e logos para os do Chatwoot.

**Produção (E7)**
- A imagem deve ser montada **sem a pasta `enterprise/`**.
- Saem Captain (assistentes), SLA, papéis customizados, auditoria, voz, capacidade de agentes e SAML.
- Companies é MIT e fica.

**Aplicar a marca**
- Rode `docker compose exec rails bundle exec rails chatclean:branding` depois de preparar o banco e a cada deploy.
- A tarefa grava nome, logos (`public/brand-assets/chatclean/`), links e `DISPLAY_MANIFEST=false`.

**Cores**
- `app/javascript/dashboard/assets/scss/_chatclean-brand.scss` troca a escala azul do Chatwoot (`--blue-*`, `--solid-blue`, `n-brand`) pelo verde da marca.
- Fundos, textos e fontes continuam os do Chatwoot.
- Ele é importado logo depois do `next-colors` em quatro lugares:
  - `app.scss` (painel);
  - `v3/App.vue` (login);
  - `portal/application.scss` (central de ajuda);
  - `survey/assets/scss/woot.scss` (pesquisa).
- Os e-mails usam `#007A2A` direto nos templates.

## Branches

| Branch | Papel | Quem escreve |
|---|---|---|
| `develop` | Espelho exato de `upstream/develop` (Chatwoot) | só `.chatclean/bin/sync-upstream` (fast-forward) |
| `main` | Produto ChatClean | só via Pull Request |
| `feature/*`, `fix/*`, `chore/*` | Trabalho | criadas a partir de `main` atualizada |

A baseline está na tag `chatclean-v1.0` (Chatwoot 4.18.0, `fbb90f7`).

```sh
git switch main && git pull --ff-only
git switch -c feature/<nome>
```

### Sincronização semanal com o Chatwoot (SOP do líder técnico, início de cada sprint)

1. **Atualizar o espelho:**
   ```sh
   .chatclean/bin/sync-upstream     # develop <- upstream/develop (--ff-only), local e origin
   ```
2. **Trazer o upstream para a `main` numa branch de alinhamento** (`XX` = número da sprint):
   ```sh
   git switch -c sync/upstream-sprint-XX origin/main
   git merge origin/develop          # conflitos com código ChatClean aparecem e são resolvidos aqui
   git push -u origin sync/upstream-sprint-XX
   ```
   Abra o PR `sync/upstream-sprint-XX → main`. O CI completo roda; o check de namespace ignora
   esse PR porque ele traz models novos do Chatwoot. Merge só com o CI verde.
3. **Propagar para as branches ativas:** em cada `feature/*` aberta, rode
   `git fetch origin && git merge origin/main` e suba de novo.

O fast-forward só acontece na `develop` e nunca conflita. Os conflitos aparecem no passo 2 e são
resolvidos na branch `sync/upstream-sprint-XX`, nunca na `develop` nem direto na `main`.

Se o fast-forward falhar, `develop` recebeu algum commit que não veio do upstream. O script
para e mostra como realinhar; `develop` nunca guarda trabalho próprio. Como o ruleset da `develop`
bloqueia force-push, realinhar o GitHub exige desativar esse ruleset por alguns instantes com a conta
dona do repositório.

Os hooks em `.chatclean/hooks/` bloqueiam commit em `main`/`develop`, push para `main` e push de
`develop` diferente de `upstream/develop`. Depois disso, eles chamam os hooks do Chatwoot em `.husky/`.
O `setup-git` copia esses hooks para `.git/chatclean-hooks/`, para que valham em qualquer branch,
inclusive na `develop`, que não tem `.chatclean/`. Rode `.chatclean/bin/setup-git` de novo quando:
- os hooks mudarem;
- algum `pnpm install` no host reapontar `core.hooksPath` para `.husky`.

O bloqueio local é uma proteção de conveniência. A proteção que vale de fato são os rulesets do
GitHub, que valem para todos, inclusive admin:

| Ruleset | Regras |
|---|---|
| `main: somente via Pull Request` | PR obrigatório (0 aprovações), check **CI ok** obrigatório, sem force-push, sem deleção |
| `develop: espelho sem force-push` | sem force-push, sem deleção (fast-forward continua liberado) |

A branch padrão do repositório é `main`. Os rulesets ficam em Settings → Rules e só a conta dona
do repositório (`dev-chatclean`) pode alterá-los.

## CI (GitHub Actions)

O workflow `.github/workflows/ci.yml` roda **só em Pull Requests** para `main` e `develop`. Commits
soltos em branches de trabalho não disparam nada. Os 17 workflows herdados do Chatwoot estão
desativados nas configurações do Actions; os arquivos continuam intactos para não gerar conflito no sync.

| Job | O que faz |
|---|---|
| RuboCop | `bundle exec rubocop --parallel` |
| ESLint | `pnpm eslint` |
| Vitest | `pnpm test` |
| Namespace CRM | reprova model novo na raiz de `app/models/` (`.chatclean/ci/check-crm-namespace.sh`) |
| Assets de teste (Vite) | compila o frontend de teste uma vez e compartilha com os jobs de RSpec |
| RSpec CRM | `zeitwerk:check` + `bundle exec rspec spec/models/crm/` |
| RSpec regressão (0–7/8) | suíte completa do core, dividida em 8 nós, com a quarentena ativa |
| **CI ok** | consolida tudo; é o check obrigatório do ruleset da `main` |

Qualquer job vermelho deixa o `CI ok` vermelho, e o merge fica bloqueado.

**Quarentena:** `.chatclean/ci/rspec-quarantine.txt` lista os testes do Chatwoot com falha conhecida,
aceitos na CCV2-1. No CI (`CHATCLEAN_RSPEC_QUARANTINE=1`) eles aparecem como pendentes. A
correspondência é por arquivo + descrição completa, então mudar a linha do teste não quebra a lista.
Nunca adicione um teste novo do ChatClean à quarentena; remova a linha quando o upstream corrigir.

## Namespace do CRM

- Models: `app/models/crm/`, herdando de `Crm::ApplicationRecord`, que prefixa as tabelas com `crm_`
  (`Crm::Deal` → `crm_deals`).
- Controllers: `app/controllers/api/v1/accounts/crm/`, herdando de `Api::V1::Accounts::BaseController`
  (rotas `/api/v1/accounts/:account_id/crm/...`). Use `::Crm::Deal` etc. dentro deles, porque o
  módulo `Api::V1::Accounts::Crm` também existe.
- Rotas: em `config/initializers/crm_routes.rb`, anexadas com `Rails.application.routes.append`. O
  `config/routes.rb` do Chatwoot não é editado.
- Policies: `app/policies/crm/` (`Crm::DealPolicy`), chamadas com `check_authorization(::Crm::Deal)`.
- Mensagens de erro: `config/locales/crm.en.yml` e `crm.pt_BR.yml`.
- Specs: `spec/models/crm/` (e equivalentes para controllers e services).
- O namespace `Crm::` já existe no Chatwoot para a integração LeadSquared (`app/services/crm/`,
  `app/jobs/crm/`). Não crie classes com os mesmos nomes. Use sempre definições compactas
  (`class Crm::Deal`), como o Chatwoot faz, para que `Contact`, `Conversation` etc. resolvam para os
  models do core.

### Migrations do CRM

Crie com o gerador (`docker compose run --rm rails bundle exec rails g migration CreateCrmX`), para ter
timestamp real. Depois do `rails db:migrate`, rode:

```sh
.chatclean/bin/after-migrate
```

O `annotaterb` reescreve anotações de dezenas de models do Chatwoot, e o dump do `schema.rb` reordena
linhas de tabelas deles. O script desfaz as mudanças que são só anotação e remonta o `schema.rb` a partir
da `main`, trocando apenas tabelas/FKs `crm_*` e a versão. Assim o PR mexe só no que é nosso.

### API de oportunidades (`/api/v1/accounts/:account_id/crm/deals`)

| Método | Uso |
|---|---|
| `GET` | lista, com filtros `status`, `crm_stage_id`, `crm_pipeline_id`, `contact_id`, `conversation_id` e paginação (`page`) |
| `GET /:id` | detalhe |
| `POST` | cria: `title`, `value`, `expected_close_date`, `crm_stage_id`, `contact_id` (contato do Chatwoot), `assignee_id`, `conversation_id` |
| `PATCH /:id` | edita e move de estágio |

**Conversa de origem (`conversation_id`):**
- Sem `contact_id`, o deal assume o contato da conversa. Se vierem os dois e forem de contatos diferentes, a API devolve 422.
- O usuário precisa enxergar a conversa (admin, ou agente da inbox ou do time, segundo a `ConversationPolicy`); senão, a API devolve 404.
- Depois de definida, a conversa de origem não pode ser trocada nem removida (422). Se a conversa for apagada no Chatwoot, o campo fica nulo.

O status do deal vem do estágio. Para ganhar, perder ou reabrir, envie o `crm_stage_id` de um estágio
`won`, `lost` ou `open` do pipeline. Perder exige `crm_loss_reason_id` (motivo ativo da conta) e aceita
`loss_details`. Ganhar ou reabrir limpa os dois. IDs de outra conta devolvem 404, e erros de validação
devolvem 422 no formato do Chatwoot (`{ message, attributes }`). O histórico de estágio, status e
motivo fica em `deal.audits`.

### API de pipelines e estágios (`/api/v1/accounts/:account_id/crm/pipelines`)

| Método | Uso | Quem |
|---|---|---|
| `GET` | lista os pipelines com os estágios em ordem (padrão primeiro, depois por nome) | todos |
| `GET /:id` | detalhe com estágios | todos |
| `POST` | cria com `name`, `description`, `is_default` | administrador |
| `PATCH /:id` | edita os mesmos campos | administrador |
| `DELETE /:id` | exclui com os estágios; recusa (422) se houver qualquer deal | administrador |
| `GET /:pipeline_id/stages` | estágios do pipeline em ordem | todos |
| `POST /:pipeline_id/stages` | cria estágio aberto com `name` e `probability` (0 a 100) | administrador |
| `PATCH /:pipeline_id/stages/:id` | edita `name` e `probability` | administrador |
| `DELETE /:pipeline_id/stages/:id` | exclui estágio aberto sem deals | administrador |
| `POST /:pipeline_id/stages/reorder` | `stage_ids` com **todos os estágios abertos** na nova ordem | administrador |

**Regras dos estágios:**
- Todo pipeline nasce com "Ganho" (won, 100%) e "Perdido" (lost, 0%), sempre no fim do funil.
- Esses dois só podem ser renomeados: não mudam de status nem de probabilidade, não são excluídos sozinhos e não entram na reordenação.
- Não existe outro estágio de ganho ou perda no mesmo pipeline.
- Um estágio aberto novo entra no fim dos abertos.
- Marcar um pipeline como padrão desmarca o anterior.

### API de motivos de perda (`/api/v1/accounts/:account_id/crm/loss_reasons`)

| Método | Uso | Quem |
|---|---|---|
| `GET` | lista em ordem alfabética, sem paginação; `?active=true` traz só os ativos | todos |
| `POST` | cria com `name` e `description` (nasce ativo) | administrador |
| `PATCH /:id` | edita `name`, `description` e `is_active` | administrador |

Não há exclusão: para aposentar um motivo, envie `is_active: false`. Nome repetido na conta, mesmo com
outra combinação de maiúsculas, devolve 422 com `attributes: ["name"]`.

## Diferenças entre a história original e o código

| História | Código |
|---|---|
| Ruby 3.2.x | `ruby '3.4.4'` no Gemfile |
| Node 18/20, Yarn | Node 24.x, pnpm 10.2.0 |
| `yarn test:unit` / `yarn lint` | `pnpm test` / `pnpm eslint` |
| Senha seed `Password123!` | `Password1!` |
| `Redis.current.ping` | removido no redis-rb 5; use `$alfred.with(&:ping)` |
| PostgreSQL 14+ com pgcrypto | `pgvector/pgvector:pg16` (pgcrypto, vector, pg_trgm, pg_stat_statements) |
| Redis 7.x | `redis:7-alpine` |
