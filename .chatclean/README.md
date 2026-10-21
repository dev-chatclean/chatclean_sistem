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
docker compose run --rm -e RAILS_ENV=test -e VITE_RUBY_AUTO_BUILD=false -e FRONTEND_URL= rails bundle exec rspec [spec/caminho_spec.rb]
```

`FRONTEND_URL=` vazio reproduz o CI, que roda sem `.env`. Com o valor de dev (`http://localhost:3000`),
o `slack_uploads_controller_spec` falha com `UnsafeRedirectError`.

Por que desligar o auto-build: o `docker/entrypoints/rails.sh` apaga `tmp/cache` a cada start, e é ali que
o `vite_ruby` guarda o registro do último build. Com o auto-build ligado, os specs que renderizam views
recompilam todo o frontend, e no container essa compilação estoura a memória padrão do Node.

RuboCop não deve rodar com o código em `/app`, como faz o `docker compose run rails`: as regras do
rubocop-rails usam padrões como `**/app/**/*.rb`, e então todo arquivo passa a contar como `app/`.
Isso gera falsos positivos em `script/` e `spec/support/`.

Se o build de assets do Vite estourar a memória (`JavaScript heap out of memory`), passe
`-e NODE_OPTIONS=--max-old-space-size=6144`.

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

Para trazer o upstream:

```sh
.chatclean/bin/sync-upstream     # develop <- upstream/develop (--ff-only), local e origin
# depois abra um PR develop -> main e resolva conflitos nele
```

Se o fast-forward falhar, `develop` recebeu algum commit que não veio do upstream. O script
para e mostra como realinhar; `develop` nunca guarda trabalho próprio.

Os hooks em `.chatclean/hooks/` bloqueiam commit em `main`/`develop`, push para `main` e push de
`develop` diferente de `upstream/develop`. Depois disso, eles chamam os hooks do Chatwoot em `.husky/`.
O `setup-git` copia esses hooks para `.git/chatclean-hooks/`, para que valham em qualquer branch,
inclusive na `develop`, que não tem `.chatclean/`. Rode `.chatclean/bin/setup-git` de novo quando:
- os hooks mudarem;
- algum `pnpm install` no host reapontar `core.hooksPath` para `.husky`.

O bloqueio local é uma proteção de conveniência. A proteção que vale de fato são as regras de branch
no GitHub (PR obrigatório na `main`), que precisam ser configuradas por um admin da organização.

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
