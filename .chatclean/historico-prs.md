# Histórico dos PRs #1 a #28

Cópia dos pull requests do repositório `dev-chatclean/chatclean_sistem`, feita em 27/10/2026 antes de ele sair da rede de fork do Chatwoot (CCV2-38). Ao sair da rede, o GitHub apaga os PRs, mas mantém os commits: o commit de merge de cada PR continua no histórico do git.

| PR | Título | Branch → base | Aberto | Mergeado | Commit de merge |
| --- | --- | --- | --- | --- | --- |
| [#1](#pr-1) | chore(dev): ambiente local isolado e governança de branches | `chore/dev-environment` → `main` | 2026-10-21 | 2026-10-21 | `50921f27cb` |
| [#2](#pr-2) | docs(dev): atualizar README e sync-upstream após os rulesets | `chore/governance-docs` → `main` | 2026-10-21 | 2026-10-21 | `109e45e292` |
| [#3](#pr-3) | CCV2-2 — Namespace CRM e pipeline de CI em Pull Requests | `feature/CCV2-2-crm-namespace-ci` → `main` | 2026-10-21 | 2026-10-21 | `49173b60fe` |
| [#4](#pr-4) | [TESTE — não mergear] CCV2-2 FA 2.1: model fora do namespace | `test/CCV2-2-fa-2-1-bloqueio` → `main` | 2026-10-21 | não mergeado | — |
| [#5](#pr-5) | CCV2-3 — Modelagem do CRM: pipelines, estágios, contatos e oportunidades | `feature/CCV2-3-crm-data-model` → `main` | 2026-10-21 | 2026-10-21 | `ba4afe2fe0` |
| [#6](#pr-6) | CCV2-4 — Ciclo de vida das oportunidades: multi-negócio, perda e API | `feature/CCV2-4-deal-lifecycle` → `main` | 2026-10-21 | 2026-10-21 | `1ba32f4141` |
| [#7](#pr-7) | CCV2-5 — API de motivos de perda e conversa de origem do deal | `feature/CCV2-5-loss-reasons-api-conversation` → `main` | 2026-10-21 | 2026-10-21 | `9810104506` |
| [#8](#pr-8) | CCV2-14 — API de pipelines e estágios (Ganho/Perdido sistêmicos, probabilidade e reordenação) | `feature/CCV2-14-pipelines-stages-api` → `main` | 2026-10-21 | 2026-10-21 | `30d0a294b4` |
| [#9](#pr-9) | CCV2-15 — Kanban de deals (arrastar, perda com motivo, responsável e conversa) | `feature/CCV2-15-kanban` → `main` | 2026-10-21 | 2026-10-21 | `80494769b4` |
| [#10](#pr-10) | CCV2-16 — Painel do CRM na conversa (deals do contato, ações rápidas e criação) | `feature/CCV2-16-conversation-panel` → `main` | 2026-10-22 | 2026-10-22 | `f2dbd583fc` |
| [#11](#pr-11) | CCV2-17 — Configurações do CRM (funis, estágios e motivos de perda) | `feature/CCV2-17-crm-settings` → `main` | 2026-10-22 | 2026-10-22 | `17c6937d22` |
| [#12](#pr-12) | CCV2-18 — Identidade visual ChatClean (logos, nome e verde da marca) | `feature/CCV2-18-branding` → `main` | 2026-10-22 | 2026-10-22 | `613ef07641` |
| [#13](#pr-13) | CCV2-20 — Edição MIT pronta para produção (imagem, compose e deploy) | `feature/CCV2-20-mit-build` → `main` | 2026-10-23 | 2026-10-23 | `fce9f9fa69` |
| [#14](#pr-14) | CCV2-22 — Marca ChatClean no Super Admin e na configuração inicial, sem chamadas Enterprise | `feature/CCV2-22-mit-cleanup` → `main` | 2026-10-23 | 2026-10-23 | `07c2d201b2` |
| [#15](#pr-15) | CCV2-19 — Infraestrutura de produção na AWS pronta para criar | `feature/CCV2-19-aws-base` → `main` | 2026-10-23 | 2026-10-23 | `39c3f36b26` |
| [#16](#pr-16) | CCV2-21 — Anexos no S3, backup diário do banco e snapshots prontos para criar | `feature/CCV2-21-s3-backups` → `main` | 2026-10-23 | 2026-10-23 | `41319711d7` |
| [#17](#pr-17) | CCV2-22 — E-mail pelo SES, alarmes e orçamento prontos para criar | `feature/CCV2-22-ses-monitoring` → `main` | 2026-10-23 | 2026-10-23 | `493a09398c` |
| [#18](#pr-18) | CCV2-36 — CRM: o atendente só vê as próprias oportunidades | `feature/CCV2-36-crm-deal-visibility` → `main` | 2026-10-24 | 2026-10-26 | `6271e0e497` |
| [#19](#pr-19) | CCV2-29 — Vocabulário, menu e barra superior da ChatClean | `feature/CCV2-29-vocabulary-menu` → `main` | 2026-10-26 | 2026-10-26 | `870ebd08dd` |
| [#20](#pr-20) | feat(chatclean): CCV2-23 conversation screen in the ChatClean format | `feature/CCV2-23-conversation-screen` → `main` | 2026-10-26 | 2026-10-26 | `7406ed9560` |
| [#21](#pr-21) | feat(chatclean): CCV2-24 mandatory closing reasons with sale value | `feature/CCV2-24-closing-reasons` → `main` | 2026-10-26 | 2026-10-26 | `fcacc75995` |
| [#22](#pr-22) | feat(chatclean): CCV2-23 tabs Ativos, Pendentes and Fechados always with counts | `feature/CCV2-23-tab-counts` → `main` | 2026-10-26 | 2026-10-26 | `e029bb5cb1` |
| [#23](#pr-23) | feat(chatclean): CCV2-26 agent name on top of the message when the signature is on | `feature/CCV2-26-agent-signature` → `main` | 2026-10-26 | 2026-10-26 | `014e450ead` |
| [#24](#pr-24) | feat(chatclean): CCV2-23 Criar atendimento dialog with phone, channel and team | `feature/CCV2-23-start-conversation` → `main` | 2026-10-26 | 2026-10-26 | `9a9d9cf57b` |
| [#25](#pr-25) | feat(chatclean): CCV2-25 canned responses by team and user, with attachments | `feature/CCV2-25-canned-responses` → `main` | 2026-10-26 | 2026-10-26 | `82b46fbc34` |
| [#26](#pr-26) | feat(chatclean): CCV2-27 account business hours and holidays | `feature/CCV2-27-account-hours` → `main` | 2026-10-26 | 2026-10-26 | `f91d43270a` |
| [#27](#pr-27) | feat(chatclean): CCV2-29 translation sweep and Portuguese as the system default language | `feature/CCV2-29-translation-sweep` → `main` | 2026-10-26 | 2026-10-26 | `9b0fdfbeea` |
| [#28](#pr-28) | chore(release): CCV2-37 keep only Chatwoot with ChatClean logos and name on main | `chore/CCV2-37-main-chatwoot-original` → `main` | 2026-10-27 | 2026-10-27 | `fe78c97825` |

---

<a id="pr-1"></a>

## #1 chore(dev): ambiente local isolado e governança de branches

- Autor: Bricio29
- Branch: `chore/dev-environment` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `50921f27cbb33e65748782d45d2f517fec7098db`

### Descrição

Este PR configura o ambiente de desenvolvimento do ChatClean sobre a baseline `chatclean-v1.0` (Chatwoot 4.18.0, `fbb90f7`). Ele também define o fluxo de branches para receber atualizações do Chatwoot sem conflitos destrutivos. Os arquivos ChatClean ficam em caminhos que não existem no upstream (`.chatclean/`, `docker-compose.override.yaml` e um initializer novo), então os merges futuros do `chatwoot/chatwoot` não geram conflito neles.

## O que muda
- **Docker isolado** (`docker-compose.override.yaml`): projeto `chatclean` com imagens próprias, Redis 7, dados do Postgres em volume nomeado, healthchecks e portas presas a `127.0.0.1`. Também corrige o host do Vite (`VITE_RUBY_HOST`), que faltava no compose upstream.
- **Governança Git**:
  - `develop` é espelho do upstream e só anda em fast-forward via `.chatclean/bin/sync-upstream`.
  - `main` recebe mudanças só por PR.
  - Hooks locais bloqueiam commit em `main`/`develop` e chamam os hooks do Chatwoot em seguida.
- **FA 1.3**: o `rails server` aborta no boot com `[ChatClean] Redis heartbeat ausente em <host:porta>` quando o Redis não responde. O Sidekiq já fazia isso nativamente.
- **`.chatclean/README.md`**: setup, comandos de teste/lint equivalentes ao CI e diferenças entre a história e o código.

## Como testar
1. Siga a seção "Primeira configuração" do `.chatclean/README.md`.
2. Acesse http://localhost:3000 e faça login com `john@acme.inc` / `Password1!`.
3. Crie um Website Channel.
4. `docker compose stop redis && docker compose run --rm --no-deps rails bundle exec rails s`: o boot aborta com a mensagem do heartbeat.
5. `git switch main && git commit --allow-empty -m x`: o commit é bloqueado.

## Baseline validada localmente
| Verificação | Resultado |
|---|---|
| Vitest | 506 arquivos, 5193 testes, 0 falhas |
| ESLint | 0 erros (453 avisos) |
| RuboCop | 3261 arquivos, 0 ofensas |
| RSpec (inclui `enterprise/`) | 10.792 exemplos, **8 falhas**, 128 pendentes |

As 8 falhas do RSpec são do próprio upstream e passam isoladas, exceto a última:
- `spec/enterprise/models/inbox_spec.rb` (3): o `message_tracking_spec` desliga transações e deixa audits de `Inbox` no banco.
- `spec/enterprise/services/llm/base_ai_service_spec.rb` (2): o `Llm::Config.initialize!` fica memorizado de um spec anterior sem `CAPTAIN_OPEN_AI_API_KEY`.
- `spec/models/conversation_spec.rb:1163,1191` (2): usam o relógio real sem `freeze_time` e passam de 1 s de tolerância com a CPU carregada.
- `spec/enterprise/services/voice/call_transcription_service_spec.rb:77` (1): exige OpenSearch configurado na carga da classe. Com OpenSearch configurado, outros 2 testes do mesmo arquivo falham.

O CI público do Chatwoot remove `enterprise/` antes de rodar, por isso 6 dessas falhas não aparecem lá.

## Pendente (requer admin da organização)
- Ruleset na `main`: PR obrigatório, sem force-push e sem deleção.
- Ruleset na `develop`: sem force-push.
- Default branch → `main`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-2"></a>

## #2 docs(dev): atualizar README e sync-upstream após os rulesets

- Autor: Bricio29
- Branch: `chore/governance-docs` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `109e45e292b257628457d1c11fb9508c00d90bbf`

### Descrição

Atualiza a documentação de governança depois da criação dos rulesets no GitHub.

## O que muda
- **`.chatclean/bin/sync-upstream`:** quando a `develop` diverge do upstream (FA 1.1), a mensagem deixa de sugerir um force-push direto, que o ruleset agora bloqueia. O novo passo a passo:
  1. levar os commits extras para uma branch, se forem trabalho válido;
  2. realinhar a `develop` local;
  3. desativar por alguns instantes o ruleset da `develop` com a conta dona do repositório para fazer o force-push.
- **`.chatclean/README.md`:** troca o aviso "precisa de admin" pela tabela dos rulesets ativos em `main` e `develop`. Também registra que a branch padrão é `main`.

## Como testar
1. `.chatclean/bin/sync-upstream` sincroniza a `develop` em fast-forward normalmente, o que mostra que o ruleset não bloqueia fast-forward.
2. Leia a seção "Branches" do `.chatclean/README.md`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-3"></a>

## #3 CCV2-2 — Namespace CRM e pipeline de CI em Pull Requests

- Autor: Bricio29
- Branch: `feature/CCV2-2-crm-namespace-ci` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `49173b60fea6d6a107c24b420a33149252c99a29`

### Descrição

Fundação do módulo de CRM e esteira de CI do ChatClean (US 02 — [CCV2-2](https://chatclean.atlassian.net/browse/CCV2-2)).

## O que muda
- **Namespace `Crm::`:**
  - `Crm::ApplicationRecord` é a base abstrata dos models do CRM e prefixa as tabelas com `crm_` (`Crm::Deal` → `crm_deals`).
  - O namespace convive com a integração LeadSquared que já existe no Chatwoot (`app/services/crm/`).
- **CI (`.github/workflows/ci.yml`):** roda só em `pull_request` para `main`/`develop`. Jobs:
  - RuboCop, ESLint e Vitest;
  - check de namespace (FA 2.3);
  - RSpec do CRM com `zeitwerk:check`;
  - regressão completa do core em 8 nós.

  O frontend de teste é compilado uma vez e compartilhado entre os jobs. O job **CI ok** consolida tudo e vira o check obrigatório da `main`.
- **Quarentena:** os 8 testes do Chatwoot com falha conhecida (exceção aceita na CCV2-1) aparecem como pendentes no CI, por arquivo + descrição. Qualquer falha nova bloqueia o merge.
- **Workflows herdados:** os 17 workflows do Chatwoot foram desativados nas configurações do Actions, sem alterar os arquivos.
- **SOP semanal de sync (CA 2.4):** documentado no `.chatclean/README.md`, com a branch `sync/upstream-sprint-XX` (FA 2.2). O `sync-upstream` passou a apontar para esse fluxo.

## Como testar
1. Este próprio PR dispara o CI; todos os jobs devem ficar verdes.
2. Em um PR de teste, um model novo em `app/models/` (raiz) deve deixar o job "Namespace CRM" e o "CI ok" vermelhos.
3. Depois do merge, o "CI ok" passa a ser obrigatório no ruleset da `main`, e PR com CI vermelho não pode ser mergeado.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-4"></a>

## #4 [TESTE — não mergear] CCV2-2 FA 2.1: model fora do namespace

- Autor: Bricio29
- Branch: `test/CCV2-2-fa-2-1-bloqueio` → `main`
- Aberto em 2026-10-21; não mergeado

### Descrição

PR descartável para validar que o CI reprova um model na raiz de `app/models/` e que o ruleset bloqueia o merge. Será fechado sem merge.

### Comentários

**Bricio29** em 2026-10-21:

Teste do FA 2.1 concluído: o job Namespace CRM e o CI ok falharam e o GitHub marcou o merge como BLOCKED. Fechado sem merge.

---

<a id="pr-5"></a>

## #5 CCV2-3 — Modelagem do CRM: pipelines, estágios, contatos e oportunidades

- Autor: Bricio29
- Branch: `feature/CCV2-3-crm-data-model` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `ba4afe2fe005dd54c5ced81481f49a36dd05de32`

### Descrição

Modelagem de dados do CRM (US 03, [CCV2-3](https://chatclean.atlassian.net/browse/CCV2-3)): pipelines com estágios ordenados, vínculo 1:1 com os contatos do Chatwoot e oportunidades (deals). Escopo só de modelagem; API e telas ficam para as próximas histórias.

## O que muda
- **Tabelas** `crm_pipelines`, `crm_stages`, `crm_contacts`, `crm_deals`, todas com PK bigint e `account_id`:
  - `ON DELETE CASCADE` ao apagar a conta.
  - Vínculo único `(account_id, contact_id)`; apagar o contato no Chatwoot apaga o vínculo e os deals (coerente com a exclusão da LGPD).
  - `value` em `decimal(12,2)`, com check constraint contra negativos.
  - Um pipeline padrão por conta.
  - `assignee_id` anulado se o usuário for removido.
- **Models** `Crm::Pipeline`, `Crm::Stage`, `Crm::Contact`, `Crm::Deal`:
  - O **status do estágio define o status do deal** (mover para um estágio ganho/perdido/aberto marca o deal).
  - Pipeline e estágio com deals não podem ser excluídos (mensagem explicativa, FA 3.1).
  - Registros de outra conta são rejeitados (FA 3.2), incluindo o responsável, que precisa ser agente da conta.
  - `Crm::Contact.for_contact!` devolve o vínculo existente ou cria um, mesmo com requisições simultâneas (FA 3.3).
- **Decisões do PO aplicadas:** colunas com prefixo `crm_` (`crm_pipeline_id`, `crm_stage_id`, `crm_contact_id`) e responsável como `assignee_id`, em vez dos nomes do texto original, que não batiam com as associações.
- O `schema.rb` muda **só** com as tabelas do CRM e a versão. Anotações de models do Chatwoot reescritas pelo annotate ficaram de fora, para não gerar conflito no sync.
- Mensagens de erro em arquivos próprios (`config/locales/crm.en.yml` e `crm.pt_BR.yml`).

## Como testar
1. `docker compose run --rm rails bundle exec rails db:migrate` cria as 4 tabelas.
2. No `rails console`: crie um pipeline com estágios "Proposta" (open) e "Fechado" (won), um deal no primeiro e mova-o para o segundo. O deal fica `won`.
3. Tente excluir o estágio com o deal: a exclusão é recusada com a mensagem para mover os deals.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-6"></a>

## #6 CCV2-4 — Ciclo de vida das oportunidades: multi-negócio, perda e API

- Autor: Bricio29
- Branch: `feature/CCV2-4-deal-lifecycle` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `1ba32f4141d6b611140f6ea75a3f8b7fd45e57a5`

### Descrição

Ciclo de vida das oportunidades (US 04, [CCV2-4](https://chatclean.atlassian.net/browse/CCV2-4)): vários negócios por contato, perda com motivo obrigatório, ganho sem formulário extra, valores em BRL e a API de deals.

## O que muda
- **Motivos de perda cadastrados (`crm_loss_reasons`).** Seguem o modelo da US 05, por decisão do PO.
  - Os deals ganham `crm_loss_reason_id` + `loss_details`, em vez de `loss_reason` em texto livre.
  - O nome do motivo é único por conta, sem diferenciar maiúsculas, e isso também é garantido no banco.
- **Regras do deal:**
  - Perder exige um motivo **ativo** da mesma conta.
  - Ganhar não exige nada.
  - Ganhar ou reabrir limpa motivo e observações.
  - Moeda travada em BRL (validação e check constraint).
  - Contato bloqueado não recebe deal novo.
  - Vários deals por contato, no mesmo pipeline ou em pipelines diferentes.
- **Histórico (FA 3.2):** mudanças de estágio, status, motivo, valor e responsável ficam em `deal.audits` (gem `audited`), fora da tela de auditoria da conta.
- **API** `GET/POST/PATCH /api/v1/accounts/:account_id/crm/deals`:
  - O status vem do estágio de destino.
  - IDs de outra conta devolvem 404.
  - Erros de validação devolvem 422 no formato do Chatwoot (`{ message, attributes }`).
  - As rotas ficam em `config/initializers/crm_routes.rb`; o `config/routes.rb` do Chatwoot não foi editado.
- **Índices:** `[account_id, status]` e `[crm_contact_id, status]`. Este último substitui o índice simples de `crm_contact_id`.
- **`.chatclean/bin/after-migrate`:** depois de cada migration, desfaz as anotações reescritas em models do Chatwoot e remonta o `schema.rb` só com as mudanças `crm_*`.

## Diferenças em relação ao texto da história
- O motivo de perda segue o modelo da US 05 (decisão do PO). A US 05 fica com a conversa de origem e a tela/API de configuração dos motivos.
- Ganhar ou perder pela API é mover o deal para um estágio `won`/`lost` (o estágio define o status, decisão da US 03). O payload `status: "lost"` da história vira `crm_stage_id` de um estágio perdido.
- Os erros seguem o formato padrão do Chatwoot, e não `{ error, details }` (decisão do PO).

## Como testar
1. `rails db:migrate` cria a tabela de motivos e as colunas novas.
2. Crie, pela API ou no console, um pipeline com estágios open/won/lost, um motivo de perda e um deal no estágio open.
3. `PATCH` para o estágio lost **sem** motivo → 422 com `attributes: ["loss_reason"]`. **Com** motivo → `status: "lost"`.
4. `PATCH` de volta para o estágio open → `status: "open"`, sem motivo nem observações.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-7"></a>

## #7 CCV2-5 — API de motivos de perda e conversa de origem do deal

- Autor: Bricio29
- Branch: `feature/CCV2-5-loss-reasons-api-conversation` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `9810104506a961fd76ce4fbcd9f466733dbb45c8`

### Descrição

API de gestão dos motivos de perda e vínculo da oportunidade com a conversa do Chatwoot que a originou (US 05, [CCV2-5](https://chatclean.atlassian.net/browse/CCV2-5)). Escopo só de backend e API; as telas ficam para as US 07 e US 09.

## O que muda
- **`crm_deals.conversation_id`** com `ON DELETE SET NULL` (CA 5.1, FA 5.4).
  - A conversa precisa ser da conta e do contato do deal (CA 5.2).
  - Depois de definida, não pode ser trocada **nem removida** (CA 5.9). Só a exclusão da conversa no Chatwoot limpa o campo.
  - Registrada no histórico (`audited`).
- **API de deals:**
  - Aceita `conversation_id`; sem `contact_id`, o deal assume o contato da conversa.
  - Contato divergente da conversa devolve 422 com `attributes: ["conversation_id"]`.
  - O usuário precisa enxergar a conversa pela `ConversationPolicy` do Chatwoot (admin, ou agente da inbox ou do time). Sem acesso, ou conversa de outra conta, devolve **404** (CA 5.8).
  - Novo filtro `?conversation_id=` e campo `conversation_id` no JSON.
- **API de motivos** `GET/POST/PATCH /api/v1/accounts/:account_id/crm/loss_reasons` (CA 5.3–5.7):
  - Lista em ordem alfabética, sem paginação, com `?active=true`.
  - Administrador cria e edita; agente só lista.
  - Sem endpoint de exclusão: o motivo é inativado com `is_active: false`.
  - Nome duplicado (sem diferenciar maiúsculas) devolve 422 com `attributes: ["name"]`.

## Diferenças de implementação em relação ao texto
- **Checagem de acesso à conversa:** feita com `ConversationPolicy#show?` direto, e não com o `authorize` do Pundit. Assim o resultado é 404, como pede o CA 5.8; o `authorize` devolveria 401. A checagem vale na criação e na edição.
- **Remoção do vínculo:** a imutabilidade também impede remover o `conversation_id`. A validação sugerida no texto só rodava com conversa preenchida e deixaria apagar o vínculo.
- **Mensagens de erro:** vêm de `crm.en.yml` / `crm.pt_BR.yml`. O `message` traz o texto real da validação, no padrão do Chatwoot.

## Como testar
1. `rails db:migrate` adiciona a coluna.
2. `POST /crm/deals` com `title`, `crm_stage_id` e `conversation_id` (sem `contact_id`): o deal nasce com o contato da conversa.
3. Como agente sem acesso à inbox da conversa, a mesma chamada devolve 404.
4. `PATCH` trocando o `conversation_id`: 422.
5. `POST /crm/loss_reasons` como agente: 401. Como admin: 200. Nome repetido: 422.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-8"></a>

## #8 CCV2-14 — API de pipelines e estágios (Ganho/Perdido sistêmicos, probabilidade e reordenação)

- Autor: Bricio29
- Branch: `feature/CCV2-14-pipelines-stages-api` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `30d0a294b4e45b30dc8c1d3eecde91d3c7193d2a`

### Descrição

API para gerenciar funis de venda e suas etapas (US 06, [CCV2-14](https://chatclean.atlassian.net/browse/CCV2-14)). Todo funil passa a nascer com "Ganho" e "Perdido" protegidos, cada etapa tem probabilidade de fechamento, e as etapas abertas podem ser reordenadas em lote, pronto para o arrastar e soltar do Kanban.

## O que muda
- **Estágios sistêmicos (CA 6.1, 6.2):**
  - Todo pipeline nasce, na mesma transação, com "Ganho" (won, 100%) e "Perdido" (lost, 0%), sempre no fim do funil.
  - Os nomes saem traduzidos: Ganho/Perdido em pt-BR, Won/Lost em inglês.
  - Esses dois só podem ser renomeados, e só são excluídos junto com o pipeline.
  - Um índice único garante um ganho e um perdido por pipeline.
  - Estágios criados pela API são sempre abertos.
- **Probabilidade (CA 6.3):** `crm_stages.probability`, de 0 a 100, validada no model e no banco.
- **Exclusão de pipeline (CA 6.4):** em cascata quando não há deals; com qualquer deal, 422 com `attributes: ["base"]`.
- **Reordenação em lote (CA 6.5):**
  - `POST /crm/pipelines/:id/stages/reorder` com **todos os estágios abertos**, numa transação.
  - Lista incompleta, repetida ou com ID de outro pipeline devolve 422, sem alterar nada.
  - Ganho e Perdido não entram e ficam no fim.
- **Pipeline padrão (CA 6.6):** marcar um pipeline como padrão desmarca o anterior. Antes, um segundo padrão era recusado.
- **API (CA 6.7):**
  - CRUD de pipelines (inclui `show`) e de estágios aninhados.
  - Administrador gerencia; agente só lê.
  - Outra conta devolve 404.
- **Pipelines existentes:** a migration cria Ganho e Perdido nos que ainda não têm.

## Decisões do PO aplicadas
- Só existem os dois estágios sistêmicos (sem estágios extras de ganho ou perda), e por isso não há coluna de flag.
- A reordenação recebe só os abertos.
- A probabilidade dos abertos é livre.

## Como testar
1. `rails db:migrate` (os pipelines existentes ganham Ganho e Perdido).
2. `POST /crm/pipelines` com `name`: a resposta já traz os estágios Ganho e Perdido.
3. `POST /crm/pipelines/:id/stages` com `name` e `probability: 20`: o estágio entra antes de Ganho.
4. `PATCH` no estágio Ganho com `probability: 50`: 422. Com `name: "Fechado"`: 200.
5. `POST .../stages/reorder` com os IDs dos abertos invertidos: a ordem muda e Ganho e Perdido continuam no fim.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-9"></a>

## #9 CCV2-15 — Kanban de deals (arrastar, perda com motivo, responsável e conversa)

- Autor: Bricio29
- Branch: `feature/CCV2-15-kanban` → `main`
- Aberto em 2026-10-21; mergeado em 2026-10-21, commit `80494769b4e3352d2b5417c160468eb74be191e3`

### Descrição

Quadro Kanban de oportunidades no painel (US 07, [CCV2-15](https://chatclean.atlassian.net/browse/CCV2-15)). O time vê o funil por pipeline, arrasta os deals entre as etapas, atribui responsável pelo próprio card e abre a conversa de origem com um clique.

## O que muda
- **Quadro (CA 7.1):**
  - Nova rota `/app/accounts/:account_id/crm/kanban` e item "Funil de vendas" no menu lateral.
  - Abre no pipeline padrão (sem padrão, no primeiro) e permite trocar de pipeline.
  - Estágios abertos na ordem de `position`, com Ganho e Perdido sempre no fim.
  - Cada coluna rola sozinha, com o cabeçalho sempre visível.
  - Sem pipelines, mostra uma tela vazia explicando o que fazer.
- **Card (CA 7.2, FA 7.1):**
  - Título (até 2 linhas), valor em BRL, contato e responsável com avatar ou iniciais.
  - Sem responsável, mostra "Sem responsável".
  - Clicar no responsável abre a atribuição rápida, com busca e opção de remover.
  - O ícone de conversa aparece só quando há conversa de origem e abre `inbox_conversation` pelo `display_id`.
- **Arrastar (CA 7.3, FA 7.2):**
  - O card muda de coluna na hora. Se a API recusar, ele volta à posição de origem e aparece um toast com a mensagem do backend.
  - Deal de contato bloqueado não pode ser arrastado e mostra o selo "Bloqueado".
- **Perda (CA 7.4, FA 7.3):**
  - Soltar em Perdido abre o modal com os motivos ativos e o detalhe opcional (até 1000 caracteres).
  - Confirmar só é liberado com um motivo escolhido.
  - Cancelar ou fechar devolve o card sem chamar a API.
- **Reordenação de estágios (CA 7.5):** só administradores arrastam colunas, pela alça no cabeçalho. Ganho e Perdido não se movem. A ordem é otimista e é desfeita se a API recusar.
- **Resumo e paginação (CA 7.6, 7.7):**
  - O cabeçalho mostra quantidade e total vindos de `GET /crm/pipelines/:id/summary`.
  - Cada coluna carrega 50 cards e busca a próxima página ao chegar ao fim (IntersectionObserver).
- **Filtro de responsável:** Todos, Meus, Sem responsável ou um agente. Vale para os cards e para o resumo (`assignee_id`, aceitando `none`).
- **Recarga:** ao voltar para a aba, o quadro recarrega.
- **Contato bloqueado (backend):**
  - Bloquear um contato perde os deals abertos dele com o motivo sistêmico "Contato bloqueado", criado ou adotado por conta e protegido contra desativação.
  - Depois disso, o deal não sai de Perdido enquanto o contato estiver bloqueado.
- **JSON do deal:** passa a trazer `contact`, `assignee` e `conversation_display_id`.
- **i18n (CA 7.8):** textos em `crm.json` (en e pt_BR). Componentes feitos com `components-next`.

## Decisões do PO aplicadas
- Contato bloqueado: os deals abertos viram perda automática com o motivo "Contato bloqueado".
- O quadro recarrega ao voltar para a aba, sem tempo real.
- Seletor de pipeline, com abertura no padrão e tela vazia.
- Atribuição rápida no card, conversa na mesma aba (Ctrl/Cmd+clique abre em outra) e atalho "Meus" no filtro.

## Diferença em relação à história
Os componentes ficam em `routes/dashboard/crm/components/` e a página em `routes/dashboard/crm/pages/`, no padrão das outras telas, e não em `crm/kanban/`.

## Testes
- Vitest:
  - `DealCard.spec.js`, `LossReasonModal.spec.js` e `stores/specs/crmKanban.spec.js` (17 exemplos);
  - suíte completa com 509 arquivos e 5.210 testes passando.
- RSpec do CRM: 150 exemplos, incluindo o job de contato bloqueado, o `summary` e o filtro `assignee_id`.
- RuboCop e ESLint sem erros.

## Como testar
1. `rails db:migrate` e reinicie o Rails e o Sidekiq (o initializer do hook de contato precisa carregar).
2. Crie um pipeline com alguns estágios e deals e abra **Funil de vendas** no menu.
3. Arraste um card entre estágios abertos. Arraste para Perdido, cancele e veja o card voltar. Arraste de novo e confirme com um motivo.
4. Troque o responsável pelo card e filtre por "Sem responsável".
5. Como administrador, reordene as colunas abertas pela alça.
6. Bloqueie o contato de um deal aberto: o deal vai para Perdido com "Contato bloqueado" e fica travado.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-10"></a>

## #10 CCV2-16 — Painel do CRM na conversa (deals do contato, ações rápidas e criação)

- Autor: Bricio29
- Branch: `feature/CCV2-16-conversation-panel` → `main`
- Aberto em 2026-10-22; mergeado em 2026-10-22, commit `f2dbd583fcec8b20fab81b82ac268deae2fe1dfc`

### Descrição

Painel do CRM na tela da conversa (US 08). O agente vê os negócios do contato no painel lateral, muda estágio e responsável e cria um negócio ligado ao atendimento, sem sair do chat.

## Closes
- [CCV2-16](https://chatclean.atlassian.net/browse/CCV2-16)

## O que muda
- **Seção "Negócios (CRM)"** no painel lateral da conversa:
  - pode ser recolhida e arrastada como as outras;
  - o estado aberto/fechado fica nas preferências do usuário (`is_crm_deals_open`).
- **Lista:**
  - todos os deals do contato; os abertos aparecem primeiro, dos mais recentes para os mais antigos;
  - os ganhos e perdidos ficam recolhidos em "Ver finalizados (N)";
  - cada card mostra "Funil › Estágio", e os deals desta conversa ganham a etiqueta "Esta conversa".
- **Ações rápidas:**
  - **Estágio:** seletor no card. Escolher Perdido abre o modal de motivo da US 07; cancelar não chama a API e o seletor volta ao estágio salvo.
  - **Responsável:** atribuição rápida com busca. O menu agora é um componente compartilhado com o Kanban (`AssigneePicker`).
  - **Falhas:** se a API recusar, aparece um toast com a mensagem do backend.
- **Novo negócio:**
  - campos de título, valor (R$), funil, estágio, previsão de fechamento e responsável;
  - abre no funil padrão, no primeiro estágio aberto e com o agente atual como responsável; trocar de funil volta ao primeiro estágio aberto dele;
  - erros de validação aparecem dentro do modal.
- **Contato bloqueado:**
  - o painel mostra um aviso e desativa criar, mudar estágio e trocar responsável;
  - ao bloquear durante o atendimento, a lista recarrega depois da perda automática;
  - no card do Kanban, o responsável também fica travado.
- **Sem funil:** mensagem diferente para administrador e agente, com a criação desativada.
- **Backend:**
  - `POST /crm/deals` aceita `conversation_display_id`, o número que aparece na URL e é o único que o painel conhece, com as mesmas validações de `conversation_id`;
  - deal de contato bloqueado não troca de responsável (422);
  - as mensagens de erro do deal passam a dizer "Contato…", e não "Crm contact…".
- **Edições em arquivos do Chatwoot** (aprovadas na história): `ContactPanel.vue` (nova seção) e `useUISettings.js` (`crm_deals` na ordem padrão).

## Como testar
1. Abra uma conversa e expanda **Negócios (CRM)** no painel lateral.
2. Clique em **Novo negócio**, preencha o título e crie. O deal aparece no topo com a etiqueta "Esta conversa".
3. Troque o estágio no seletor. Escolha **Perdido**, cancele e veja o seletor voltar; repita e confirme com um motivo. O deal vai para "Ver finalizados".
4. Troque o responsável pelo nome no rodapé do card.
5. Bloqueie o contato pelo cabeçalho da conversa: aparece o aviso, as ações ficam travadas e, em alguns segundos, os deals abertos aparecem como perdidos.
6. Clique em **Ver no funil** para abrir o Kanban.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-11"></a>

## #11 CCV2-17 — Configurações do CRM (funis, estágios e motivos de perda)

- Autor: Bricio29
- Branch: `feature/CCV2-17-crm-settings` → `main`
- Aberto em 2026-10-22; mergeado em 2026-10-22, commit `17c6937d22787b2ad1324603635d0d1e05a70386`

### Descrição

Tela de configurações do CRM (US 09). Na área de configurações, o administrador cria e organiza os funis de venda e os estágios, e gerencia os motivos de perda. Com ela, o CRM passa a ser configurado sem chamadas de API.

## Closes
- [CCV2-17](https://chatclean.atlassian.net/browse/CCV2-17)

## O que muda
- **Item "CRM" nas Configurações** (só administradores), em `/settings/crm`, com duas abas: "Funis e estágios" e "Motivos de perda". A aba ativa fica na URL (`?tab=`).
- **Funis:**
  - lista com a etiqueta "Padrão";
  - criar e editar nome, descrição e padrão. Ao ligar "padrão", aparece o aviso de qual funil deixa de ser o padrão;
  - excluir com confirmação. Se o funil tiver negócios, a API recusa e um toast explica.
- **Estágios:**
  - criar e editar nome e probabilidade (inteiro de 0 a 100);
  - reordenar os abertos arrastando pela alça. Se a API recusar, a ordem volta;
  - excluir com confirmação;
  - Ganho e Perdido aparecem como "Encerramento", só podem ser renomeados e não têm botão de excluir.
- **Motivos de perda:**
  - tabela com switch de ativo/inativo;
  - criar e editar nome e descrição. Nome repetido mostra o erro no próprio campo, com o modal aberto;
  - o motivo "Contato bloqueado" tem a etiqueta "Sistema" e o switch travado.
- **Backend:** o JSON do motivo traz `is_system`, calculado pela chave interna. Por isso continua valendo depois de o motivo ser renomeado.
- **Telas vazias:** o Kanban e o painel da conversa, quando não há funil, agora mostram ao administrador o link para as configurações.
- **Edições em arquivos do Chatwoot** (aprovadas na história): `settings.routes.js` (nova rota) e `Sidebar.vue` (item no menu de configurações).

## Como testar
1. Como administrador, abra **Configurações → CRM**.
2. Crie um funil novo marcando "padrão" e veja o aviso sobre o funil anterior.
3. No funil, crie dois estágios, arraste para trocar a ordem e renomeie o "Ganho".
4. Tente excluir um funil que tem negócios: aparece o erro e o funil continua na lista.
5. Na aba **Motivos de perda**:
   - crie um motivo;
   - tente criar outro com o mesmo nome em minúsculas e veja o erro no campo;
   - desative um motivo comum;
   - confira que o switch do "Contato bloqueado" não mexe.
6. Entre como agente: o item CRM não aparece nas configurações.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-12"></a>

## #12 CCV2-18 — Identidade visual ChatClean (logos, nome e verde da marca)

- Autor: Bricio29
- Branch: `feature/CCV2-18-branding` → `main`
- Aberto em 2026-10-22; mergeado em 2026-10-22, commit `613ef07641220b2766886cbd9b2faa6cef8532ba`

### Descrição

O sistema passa a se apresentar como ChatClean.

- **Nome:** aparece no título das páginas, no login e nos e-mails.
- **Logos oficiais:** a horizontal verde no modo claro, a dourada no modo escuro, e o ícone como favicon e no menu.
- **Cores:** o verde da marca no lugar do azul do Chatwoot em botões, links, abas, bolhas das mensagens do agente e destaques. Fundos e fontes continuam os mesmos.

## Closes
- [CCV2-18](https://chatclean.atlassian.net/browse/CCV2-18)

## O que muda
- **Marca:**
  - os logos ficam em `public/brand-assets/chatclean/`;
  - a tarefa `rails chatclean:branding` grava nome, logos e links (chatclean.com.br) e desliga o manifest do Chatwoot (favicons e avisos de versão).
- **Cores:**
  - `_chatclean-brand.scss` sobrescreve a escala azul (`--blue-*`, `--solid-blue`, `--text-blue`, `--border-blue*`) com o verde da marca, nos modos claro e escuro;
  - ele é importado logo depois do `next-colors` no painel, no login, na central de ajuda e na pesquisa de satisfação;
  - o `n-brand` passa a seguir essa escala;
  - nos e-mails e no ícone de conversa aberta, o azul fixo vira `#007A2A`.
- **Edição MIT** (decisão do PO):
  - o código de `enterprise/` só pode rodar em produção com licença;
  - no ambiente local, rails e sidekiq rodam com `DISABLE_ENTERPRISE=true`; sem isso, o plano community devolveria a marca para "Chatwoot";
  - a imagem de produção sem a pasta `enterprise/` fica para o E7;
  - o RSpec continua com o Enterprise ligado, para a regressão do upstream valer.
- **Edições em arquivos do Chatwoot:**
  - `app.scss`, `v3/App.vue`, `portal/application.scss` e `survey/.../woot.scss` (uma linha de import cada);
  - `theme/colors.js` (`brand`) e `theme/icons.js` (cor do ícone de conversa aberta);
  - os dois templates de e-mail (cor).
- **Menu lateral:**
  - logo horizontal centralizada no topo, com a escolha de conta logo abaixo;
  - largura fixa: a alça de arrastar saiu;
  - o botão "Recolher menu" / "Expandir menu" fica logo acima do perfil.
- **Telas:**
  - fundo da conversa: a logo oficial no lugar da ilustração do Chatwoot, quando nenhuma conversa está aberta;
  - "Todas as conversas carregadas" termina com o isotipo dourado no lugar do 🎉;
  - os textos ficam em `chatclean.json` (en e pt_BR), sem mexer nas traduções do Chatwoot.
- **Documentação:** o `.chatclean/README.md` ganhou a seção "Marca ChatClean e edição MIT".

## Como testar
1. Recrie o rails e o sidekiq (`docker compose up -d rails sidekiq`), que passam a usar `DISABLE_ENTERPRISE=true`.
2. Rode `docker compose exec rails bundle exec rails chatclean:branding`.
3. Abra o login nos modos claro e escuro: logo verde no claro, dourada no escuro, botão "Login" verde e título "ChatClean".
4. Entre no painel: o ícone ChatClean aparece no menu e no favicon, e botões, abas e links ficam verdes.
5. Abra uma conversa: as mensagens do agente ficam em verde-claro (claro) e verde-escuro (escuro).
6. No menu: a logo fica centralizada com a conta abaixo, e "Recolher menu" (acima do perfil) recolhe e expande. A borda não arrasta mais.
7. Sem conversa aberta, a logo ChatClean aparece no centro. No fim da lista de conversas aparece o isotipo dourado.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-13"></a>

## #13 CCV2-20 — Edição MIT pronta para produção (imagem, compose e deploy)

- Autor: Bricio29
- Branch: `feature/CCV2-20-mit-build` → `main`
- Aberto em 2026-10-23; mergeado em 2026-10-23, commit `fce9f9fa699709feefe8d9989671f4b5a4b43997`

### Descrição

Prepara a edição MIT da ChatClean para ir a produção (US 11). O CI passa a testar exatamente o que vai para o servidor, e fica pronto o pacote de deploy numa máquina única. Nada é criado na AWS: o workflow de deploy fica desligado até a infraestrutura existir (US 10, depois dos créditos).

## Closes
- Parte da [CCV2-20](https://chatclean.atlassian.net/browse/CCV2-20). O deploy real e o rollback em produção são validados quando a máquina existir.

## O que muda
- **CI na edição MIT:**
  - a regressão completa e os testes do CRM rodam sem `enterprise/` e `spec/enterprise/`, o mesmo passo do workflow CE do Chatwoot;
  - o job do CRM passou a cobrir também a API e os jobs do CRM.
- **Imagem de produção:** `.chatclean/bin/build-production-image` monta a imagem a partir de um clone do commit, sem `enterprise/` e com `CW_EDITION=ce`, e confere que a pasta não entrou.
- **Pacote de produção** (`.chatclean/deploy/`):
  - **Compose:** Caddy (HTTPS automático), rails, sidekiq, postgres com pgvector e redis com persistência (`appendonly`), com healthchecks.
  - **`deploy.sh`:**
    - roda `db:chatwoot_prepare` e `chatclean:branding` com a imagem nova; se falhar, nada no ar muda;
    - recria os containers e espera o `/health`;
    - se o `/health` não responder, volta à imagem anterior.
  - **`render-env.sh`:** gera o `.env` a partir do SSM Parameter Store (`/chatclean/production/*`).
  - **`release.sh`:** entrada no servidor; baixa a imagem do ECR, copia dela os arquivos de deploy, gera o `.env` e roda o deploy.
  - **`env.production.example`** e um runbook (`README.md`).
- **Workflow `chatclean-deploy.yml`:**
  - push na `main` → imagem MIT → ECR (OIDC, sem chave fixa) → `release.sh` por SSM Run Command (sem SSH);
  - **desligado** até `CHATCLEAN_DEPLOY_ENABLED=true`.

## Validado localmente
- **Imagem montada e deploy rodado duas vezes** num projeto separado (banco novo e banco existente):
  - HTTPS 200 no `/health`;
  - HTTP redireciona para HTTPS;
  - WebSocket do `/cable` com 101;
  - logo e marca ChatClean aplicadas;
  - sem `/app/enterprise` e com `ChatwootApp.enterprise?` falso.
- **Lint:** `actionlint` e `shellcheck` sem apontamentos.

## Achados para a US 13 (CCV2-22)
- A tela de configuração inicial e o Super Admin ainda mostram a marca Chatwoot.
- Na configuração inicial, "receber novidades" vem marcada e envia ao Chatwoot a empresa, o nome e o e-mail do administrador. O runbook manda desmarcar.
- Mesmo com `DISABLE_TELEMETRY`, a instalação envia periodicamente ao Chatwoot o domínio e a versão.

## Como testar
Veja "Testar no seu computador" em `.chatclean/deploy/README.md`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-14"></a>

## #14 CCV2-22 — Marca ChatClean no Super Admin e na configuração inicial, sem chamadas Enterprise

- Autor: Bricio29
- Branch: `feature/CCV2-22-mit-cleanup` → `main`
- Aberto em 2026-10-23; mergeado em 2026-10-23, commit `07c2d201b2f49d61ebb176723ca1c8158068013b`

### Descrição

Tira os últimos resquícios do Chatwoot que a equipe veria na edição MIT (parte de código da US 13). O Super Admin e a tela de configuração inicial passam a mostrar a marca ChatClean, a configuração inicial não envia mais dados do administrador ao Chatwoot, e a tela de Agentes para de chamar uma API Enterprise que não existe. O Super Admin ganha também a opção de idioma English/Português.

## Closes
- Parte da [CCV2-22](https://chatclean.atlassian.net/browse/CCV2-22). E-mail (SES), monitoramento e orçamento ficam para depois dos créditos da AWS.

## O que muda
- **Super Admin e configuração inicial:**
  - título, logos e nome vêm da configuração da instalação (ChatClean), pelo `ChatcleanBrand.value`;
  - sem a configuração, voltam aos arquivos padrão;
  - o "Welcome to Chatwoot" da configuração inicial mostra o nome da instalação, como o `replaceInstallationName` do front.
- **Cores do Super Admin:** a folha de estilo dele redefine a escala azul do Chatwoot, então agora também importa a paleta verde da ChatClean; o gráfico do painel usa o verde de ação. Os fundos continuam os mesmos nos dois modos.
- **Menu do Super Admin recolhível,** como o do painel:
  - o botão fica logo acima do perfil;
  - recolhido, mostra só os ícones (com o nome ao passar o mouse), a marca, a busca e o avatar;
  - a escolha fica salva no navegador e vale desde o primeiro carregamento, como o tema do Super Admin (`_chatclean_sidebar`).
- **Idioma do Super Admin:**
  - o menu do perfil tem English/Português, ao lado do tema;
  - a escolha fica num cookie e vale em todas as telas do Super Admin, inclusive no login (`SuperAdminLocale`); sem ela, vale o `DEFAULT_LOCALE` da instalação;
  - o Chatwoot não tem textos do Super Admin em pt_BR, então as 296 chaves que faltam estão traduzidas em `chatclean_super_admin.pt_BR.yml`, junto com as do Administrate (que vêm como `pt-BR`);
  - datas e botões de formulário vêm do rails-i18n (`chatclean_rails.pt_BR.yml`), que também usa `pt-BR` e por isso nunca carregava; sem eles, a tela de usuário mostrava "Translation missing";
  - nomes dos recursos, rótulos dos campos, filtros e valores (status da conta, tipo de usuário) passam pelo i18n, com o inglês atual como padrão;
  - os números e as datas do gráfico do painel seguem o idioma;
  - continuam em inglês só as descrições das integrações em Configurações, que vêm dos dados de configuração do Chatwoot.
- **Sem "receber novidades" na configuração inicial:** marcada, essa opção enviava ao Chatwoot a empresa, o nome e o e-mail do primeiro administrador (`ChatwootHub.register_instance`).
- **Tela de Agentes:** só busca papéis customizados quando o Enterprise existe. Na edição MIT, a chamada dava 401 no console.
- **Edições em arquivos do Chatwoot:** `_standalone`, `_brand`, o layout do Super Admin, o template da configuração inicial, `settings/agents/Index.vue` e, para o idioma, o menu do perfil, os filtros, a lista, os campos de seleção, o selo e o painel do Super Admin. São edições pequenas, comentadas ou com o texto em inglês mantido como padrão.

## Como testar
1. Abra `/super_admin/sign_in`: o título é "SuperAdmin | ChatClean", aparecem as logos da ChatClean e o botão e o fundo do topo são verdes. Entre e veja o painel com o gráfico verde. Clique em "Collapse menu" (acima do perfil): o menu fica só com os ícones e continua assim ao recarregar.
2. Numa instalação nova (ou com a flag de onboarding ligada), `/installation/onboarding` mostra "Welcome to ChatClean" e não tem a caixa de novidades.
3. No Super Admin, abra o menu do perfil e escolha **PT** em "Language": a página recarrega em português (menu, painel, gráfico, contas, usuários, formulários). Saia e veja o login em português. Volte para **EN** e tudo retorna ao inglês.
4. Em Configurações → Agentes, o console não mostra mais erro de `/custom_roles`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-15"></a>

## #15 CCV2-19 — Infraestrutura de produção na AWS pronta para criar

- Autor: Bricio29
- Branch: `feature/CCV2-19-aws-base` → `main`
- Aberto em 2026-10-23; mergeado em 2026-10-23, commit `39c3f36b262de305674d3f5a35f6d6506ab0e0ab`

### Descrição

Deixa pronta a infraestrutura de produção na AWS, para criar com um comando assim que os créditos forem aprovados: a máquina em São Paulo com IP fixo, firewall só com HTTP e HTTPS, acesso ao terminal sem SSH, o repositório de imagens e a permissão do GitHub para fazer o deploy. Nada foi criado na AWS ainda.

## Closes
- Parte da [CCV2-19](https://chatclean.atlassian.net/browse/CCV2-19) (US 10). Ficam para depois dos créditos: criar a stack, o registro A na Hostinger e o teste de HTTPS.

## O que muda
- **Stack `chatclean-base`** (`.chatclean/infra/chatclean-base.yaml`), aplicada pela AWS CLI com `.chatclean/infra/deploy-base`:
  - EC2 `t3.large` (2 vCPU, 8 GB, x86) com Ubuntu 24.04 LTS em sa-east-1 e disco gp3 de 50 GB criptografado;
  - o disco não é apagado se a máquina for encerrada (`DeleteOnTermination: false`), há proteção contra encerramento, e máquina, IP e ECR ficam mesmo se a stack for apagada;
  - no primeiro boot: Docker Engine e Compose, AWS CLI, swap de 4 GB, `somaxconn=1024` e `overcommit_memory=1`;
  - Elastic IP;
  - Security Group só com 80 e 443: sem porta 22 e sem 5432/6379;
  - acesso ao terminal pelo SSM Session Manager; IMDSv2 obrigatório;
  - ECR `chatclean` com imagens imutáveis, varredura e as 20 mais recentes guardadas;
  - provedor OIDC do GitHub e a role `chatclean-github-deploy`, que só aceita pushes na `main`.
- **`deploy-base --dry-run`** mostra o que seria criado ou alterado e descarta, sem criar nada. Nas atualizações, o AMI fica o da criação, para a máquina não ser recriada.
- **Caddy:** HTTP agora responde 301 para HTTPS, como pede o CA 10.4 (o automático do Caddy é 308).
- **Workflow de deploy:** tira o `release.sh` da própria imagem, então a máquina nova só precisa da pasta `/opt/chatclean`.
- **Runbook** em `.chatclean/infra/README.md`: criar, conferir a máquina, DNS, teste de HTTPS, reboot e como desmontar.

**Divergências com a história:** usamos `t3.large` (x86, não `t4g`), o serviço do Caddyfile é `rails` (não `web`), e o `/cable` não precisa de bloco próprio, porque o `reverse_proxy` do Caddy já repassa o WebSocket. Os três pontos já constavam da revisão técnica.

## Como testar
Com os créditos aprovados e `aws sso login --profile ChatClean`:
1. `.chatclean/infra/deploy-base --dry-run` lista os recursos que seriam criados e não cria nada.
2. `.chatclean/infra/deploy-base` cria a stack e mostra o IP, o ID da máquina e a role de deploy.
3. Siga o runbook: registro A na Hostinger, teste de HTTPS com o Caddy de teste e reboot.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-16"></a>

## #16 CCV2-21 — Anexos no S3, backup diário do banco e snapshots prontos para criar

- Autor: Bricio29
- Branch: `feature/CCV2-21-s3-backups` → `main`
- Aberto em 2026-10-23; mergeado em 2026-10-23, commit `41319711d735f626f279678c717b106bfa498489`

### Descrição

Deixa pronta a proteção dos dados de produção, para entrar junto com a infraestrutura quando os créditos da AWS saírem. Os anexos das conversas ficam num bucket privado do S3. O banco tem backup diário por 30 dias, o disco inteiro tem snapshot diário por 7 dias, e qualquer falha de backup gera alerta por e-mail. O teste de restauração já foi feito com o banco de desenvolvimento. Nada foi criado na AWS ainda.

## Closes
- Parte da [CCV2-21](https://chatclean.atlassian.net/browse/CCV2-21) (US 12). Depois dos créditos: criar a stack, confirmar o e-mail dos alertas e repetir o teste de restauração com um dump de produção.

## O que muda
- **Stack `chatclean-base`** ganha:
  - bucket `chatclean-attachments-<conta>` para os anexos: bloqueio de acesso público, criptografia SSE-S3, acesso pela role da máquina (sem chave no `.env`);
  - bucket `chatclean-backups-<conta>`: os dumps em `database/` expiram em 30 dias;
  - snapshot diário do disco pelo Data Lifecycle Manager às 03:30 de Brasília, guardando 7;
  - tópico `chatclean-alerts` com assinatura por e-mail (`desenvolvimento@chatclean.com.br`, ajustável).
- **`backup-db.sh`** às 03:00 de Brasília (cron instalado pelo `release.sh`):
  - faz o `pg_dump` com gzip, envia para o bucket e apaga o arquivo local;
  - não roda se o disco tiver menos de 10 GB livres;
  - em qualquer falha, avisa por e-mail; o log fica em `/var/log/chatclean_backup.log`.
- **`restore-check.sh`** restaura um dump num Postgres temporário (pgvector) e conta as linhas de cada tabela, para comparar com produção (`count-rows.sql`).
- **Runbook** "Backup e recuperação" em `.chatclean/deploy/README.md`: teste de restauração, banco perdido com a máquina boa e máquina perdida (recriada pelo snapshot, com o mesmo IP).
- A preparação da máquina pode rodar de novo numa máquina recriada a partir de snapshot.

**Sem mudança no código do Chatwoot:** o `storage.yml` já tem o serviço `amazon` (`ACTIVE_STORAGE_SERVICE=amazon`, `S3_BUCKET_NAME`, `AWS_REGION`). Conferi que, com as chaves vazias, o SDK usa a role da máquina. Os uploads diretos do navegador vêm desligados, então o bucket não precisa de CORS.

**Testado localmente:**
- dump do banco de desenvolvimento restaurado com as 111 tabelas iguais, inclusive `crm_*`;
- `backup-db.sh` com a AWS CLI simulada nos três casos: envio, disco cheio e Postgres parado (os dois últimos geram o alerta e não deixam arquivo para trás).

## Como testar
Depois dos créditos:
1. `.chatclean/infra/deploy-base --dry-run` lista os buckets, a política de snapshots e o tópico.
2. Depois de criar, confirme o e-mail de assinatura do `chatclean-alerts`.
3. Na máquina: `sudo /opt/chatclean/backup-db.sh` e o arquivo aparece em `s3://chatclean-backups-<conta>/database/`.
4. Siga o "Teste de restauração" do runbook.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-17"></a>

## #17 CCV2-22 — E-mail pelo SES, alarmes e orçamento prontos para criar

- Autor: Bricio29
- Branch: `feature/CCV2-22-ses-monitoring` → `main`
- Aberto em 2026-10-23; mergeado em 2026-10-23, commit `493a09398c23e8e242f3bfc07c183aef0a9e3fa7`

### Descrição

Deixa pronta a parte da AWS da US 13: o sistema passa a mandar e-mails (convites, troca de senha, notificações) pelo Amazon SES, com o domínio autenticado para não cair no spam. Ganha também alarmes por e-mail quando a máquina tiver problema ou o gasto passar do orçamento. Nada foi criado na AWS e nenhum registro de DNS foi alterado.

## Closes
- Parte da [CCV2-22](https://chatclean.atlassian.net/browse/CCV2-22) (US 13). A parte de código (marca no Super Admin, tela de Agentes, idioma) entrou no PR #14. Depois dos créditos: criar a stack, os registros na Hostinger e o pedido de saída da sandbox do SES.

## O que muda
- **SES:**
  - verifica `chatclean.com.br` por DKIM (3 CNAMEs, que saem prontos nas saídas da stack);
  - usa `bounce.chatclean.com.br` como MAIL FROM, com SPF próprio;
  - o SPF da raiz, usado pelo e-mail da Hostinger (`include:_spf.mail.hostinger.com`), **não muda**, e mesmo assim o e-mail passa no DMARC;
  - DMARC começa com `p=none` e relatórios para `desenvolvimento@chatclean.com.br`.
- **Credenciais SMTP:** usuário IAM que só envia e-mail. O `.chatclean/infra/ses-smtp-credentials` cria a chave, converte na senha SMTP do SES e grava `SMTP_USERNAME`/`SMTP_PASSWORD` no Parameter Store, sem mostrar a senha na tela nem passá-la na linha de comando.
- **Monitoramento:**
  - o CloudWatch Agent, instalado no primeiro boot, envia memória, disco e o log de acesso do Caddy (agora em JSON numa pasta montada, guardado 30 dias);
  - alarmes por e-mail (tópico `chatclean-alerts`) para:
    - CPU > 85% por 10 min;
    - memória > 90% por 10 min;
    - disco > 80%;
    - mais de 20 erros 5xx em 5 min;
    - máquina sem resposta;
    - falha de host da AWS, que recupera a máquina sozinha com o mesmo disco e IP.
- **Orçamento:** US$ 150/mês sobre o gasto **bruto** (os créditos não escondem o consumo), com e-mail em 80%, 100% e na previsão de 100%.
- **Runbook** com os registros da Hostinger, a conferência do domínio e o pedido de saída da sandbox (texto pronto).

**Divergências com a história:**
- o SPF fica no subdomínio `bounce` e não na raiz, para não arriscar o e-mail da Hostinger;
- o orçamento é de US$ 150, decisão do PO;
- o DMARC manda os relatórios para `desenvolvimento@`, porque `dmarc-reports@` não existe.

**Testado localmente:**
- o Caddy grava uma linha JSON por acesso com o `status`, o campo que o filtro de 5xx usa;
- a configuração do CloudWatch Agent passou na validação do próprio agente num Ubuntu 24.04;
- o `ses-smtp-credentials` foi testado com a AWS CLI simulada: grava os dois parâmetros, e a chave secreta não aparece na tela nem nos argumentos;
- o template passou no cfn-lint e os scripts no shellcheck.

## Como testar
Depois dos créditos:
1. `.chatclean/infra/deploy-base --dry-run` lista a identidade do SES, o usuário SMTP, os alarmes e o orçamento.
2. Depois de criar, cadastre os registros da seção "E-mail pelo SES" do `.chatclean/infra/README.md` e confira a verificação.
3. Rode `ses-smtp-credentials`, faça um deploy e convide um agente com um e-mail verificado (enquanto o SES estiver na sandbox): o convite chega fora do spam.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-18"></a>

## #18 CCV2-36 — CRM: o atendente só vê as próprias oportunidades

- Autor: Bricio29
- Branch: `feature/CCV2-36-crm-deal-visibility` → `main`
- Aberto em 2026-10-24; mergeado em 2026-10-26, commit `6271e0e497d571445ad6ff2aaa0e74871d25e392`

### Descrição

No CRM, cada atendente passa a ver e editar só as oportunidades em que é o responsável. O administrador continua vendo todas e é o único que troca o responsável. Assim a carteira de cada vendedor fica protegida e os números de cada um não se misturam.

## Closes
- [CCV2-36](https://chatclean.atlassian.net/browse/CCV2-36) (US 27)

## O que muda
- **Para o atendente:**
  - Kanban, painel de oportunidades na conversa e totais das colunas mostram só as oportunidades dele;
  - as de outros responsáveis e as sem responsável não aparecem; abrir ou alterar uma delas pelo endereço responde "não encontrado";
  - a oportunidade que ele cria é sempre dele, mesmo que a requisição mande outro responsável;
  - ele não troca o responsável (a API responde "não autorizado").
- **Para o administrador:** nada muda. Vê, cria, edita e reatribui todas.
- **Oportunidades sem responsável**, inclusive as antigas, ficam visíveis só para o administrador. Não há migração, por decisão do PO.
- **Tela:** o seletor de responsável do card, o filtro por responsável do Kanban e o campo "Responsável" do diálogo de nova oportunidade aparecem só para o administrador. Para o atendente, o card mostra o responsável sem permitir troca.
- **Testes:** os que esperavam o comportamento antigo (atendente mexendo em oportunidades de outros) passaram a usar o papel certo. Entraram testes de listagem, acesso direto, criação, troca de responsável e resumo por etapa para os dois papéis, e testes de tela para o atendente.

## Como testar
1. Entre como atendente: no Pipeline, só aparecem as oportunidades dele, os totais das colunas batem com elas e não há filtro de responsável nem troca de responsável no card.
2. Numa conversa, crie uma oportunidade: o campo de responsável não aparece e ela nasce com o atendente como responsável.
3. Entre como administrador: aparecem todas as oportunidades, com o filtro e a troca de responsável.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-19"></a>

## #19 CCV2-29 — Vocabulário, menu e barra superior da ChatClean

- Autor: Bricio29
- Branch: `feature/CCV2-29-vocabulary-menu` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `870ebd08dd733b407cccb00079bc0a22c3b394d2`

### Descrição

O painel em português passa a falar como a ChatClean atual, com o menu na mesma organização e uma barra superior. Como a equipe de suporte é a mesma nos dois sistemas, os nomes e a navegação agora são iguais.

## Closes
- [CCV2-29](https://chatclean.atlassian.net/browse/CCV2-29) (US 14)

## O que muda
- **Vocabulário (pt_BR):**

  | Antes | Agora |
  |---|---|
  | Conversa | Atendimento |
  | Caixa de entrada | Canal |
  | Time | Departamento |
  | Agente | Atendente (na tela de cadastro, Usuário) |
  | Resposta pronta | Mensagem rápida |
  | Atributo personalizado | Campo customizado |
  | Aplicativos do painel | Plugins |
  | Campanha | Envio |
  | Resolver / resolvida | Fechar / fechado |
  | Nota privada | Nota interna |

  - **1.074 frases** reescritas uma a uma, com a concordância certa ("o atendimento foi atribuído", "todos os atendimentos abertos", "Abertos", "Sem resposta").
  - Algumas traduções erradas do Chatwoot foram corrigidas pelo caminho, como "Agente excluído" para um canal apagado.
  - Exceções mantidas: a caixa de entrada do e-mail do usuário e a de notificações, o "time" do Linear, o agente robô e as conversas do WhatsApp.
  - Onde "time" queria dizer a equipe inteira, ficou "equipe".
  - O inglês não muda.
- **Como fica no código:**
  - As frases ficam em `pt_BR/chatcleanVocabulary.json`, só as alteradas, aplicadas por cima das do Chatwoot. Num sync com o Chatwoot, as frases novas continuam aparecendo.
  - O teste do vocabulário lista as que ainda usam termos antigos.
- **Menu lateral:**
  - Na ordem da ChatClean: Dashboards, Atendimentos, Contatos (com Empresas), Funil de vendas, Envios, Canais, Central de ajuda, Configurações.
  - Saem Automação, Macros e envios por SMS.
  - Na criação de canal não aparecem SMS nem telefonia.
  - Para o atendente continuam escondidos Dashboards, Envios e Canais.
- **Barra superior:**
  - Atalho para Atendimentos, sino de notificações com o contador (que antes era o item "Caixa de entrada" do menu) e o menu do perfil, que agora abre para baixo.
  - O botão "Recolher menu" continua no rodapé do menu lateral.
  - No celular, o perfil continua no menu lateral.
  - Os atalhos de Chat interno e Mensagens agendadas entram com as US 26 e 25.
- **Isotipo no menu recolhido:** verde no modo claro e dourado no modo escuro (`chatclean/BrandIcon.vue`).
- **Edições em arquivos do Chatwoot:** pequenas e comentadas.
  - `Sidebar.vue`: a lista passa pelo `chatcleanMenu`, e o perfil fica só no celular.
  - `SidebarProfileMenu.vue`: opção de abrir para baixo.
  - `Dashboard.vue`: a barra superior.
  - `ChannelList.vue`: esconde SMS e telefonia.
  - `pt_BR/index.js`: aplica o vocabulário.

## Como testar
1. Entre como administrador:
   - o menu aparece na ordem nova, com "Canais" no menu principal e "Empresas" dentro de Contatos;
   - a barra superior tem Atendimentos, o sino e o perfil;
   - as telas falam em atendimentos, canais, departamentos, usuários, mensagens rápidas e envios.
2. Em Canais → Adicionar canal, não há SMS nem telefonia.
3. Entre como atendente: Dashboards, Envios e Canais não aparecem.
4. Troque o idioma do perfil para inglês: os termos voltam aos originais.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-20"></a>

## #20 feat(chatclean): CCV2-23 conversation screen in the ChatClean format

- Autor: Bricio29
- Branch: `feature/CCV2-23-conversation-screen` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `7406ed95607ac0313a9ba99cb7ae67922ba0cdc7`

### Descrição

A tela de atendimento passa a funcionar como na ChatClean atual: abas Ativos, Pendentes, Todos e Fechados, cards com etiquetas coloridas e aviso de cliente esperando, e um cabeçalho com Aceitar, Fila, Transferir e Fechar. Com isso, o atendente pega um atendimento da fila, devolve, transfere com um recado para o colega ou reabre um fechado sem sair da conversa.

## Closes
- [CCV2-23](https://chatclean.atlassian.net/browse/CCV2-23) (US 15)

## O que muda
- **Abas da lista:**
  - Ativos (meus), Pendentes (sem atendente), Todos e **Fechados**.
  - "Fechados" fica ao lado de "Todos" e mostra todos os atendimentos fechados.
  - Enquanto "Fechados" está aberta, as abas não mostram contador, porque os números do Chatwoot valem para o status em uso.
- **Card do atendimento:**
  - Ícone do canal sobre a foto do contato.
  - Número do atendimento.
  - Etiquetas coloridas:
    - canal: só quando há mais de um canal;
    - atendente: ícone de robô para o assistente de IA, escondida na aba Ativos;
    - departamento.
  - Barra amarela à esquerda quando a última mensagem é do cliente, ou seja, ele está esperando resposta.
- **Cabeçalho:**
  - Telefone do contato ao lado do número.
  - **Aceitar** (sem atendente):
    - atribui o atendimento a quem clicou;
    - se outra pessoa aceitou antes, avisa "Atendimento já aceito por Fulano".
  - **Fila** (com atendente): devolve o atendimento para Pendentes.
  - **Transferir:** escolhe departamento e/ou atendente (só quem tem acesso ao canal) e um recado opcional, que vira nota interna.
  - **Fechar** e **Reabrir** são os do Chatwoot.
  - Num atendimento fechado ficam só Transferir e Reabrir.
- **Lista:** botão "Iniciar atendimento" no topo, que abre o envio de nova mensagem do Chatwoot.
- **Rodapé:**
  - O campo de texto explica o Shift + Enter e o "/".
  - Um botão abre as mensagens rápidas.
- **Menu lateral:** começa recolhido.
- **Backend:**
  - `POST conversations/:id/acceptance`: aceite com trava no banco, para que dois atendentes não peguem o mesmo atendimento.
  - `POST conversations/:id/transfer`:
    - departamento, atendente e nota numa só transação;
    - devolve 422 sem destino ou com atendente sem acesso ao canal.
  - As rotas ficam em `config/initializers/chatclean_routes.rb`.
- **Edições em arquivos do Chatwoot**, pequenas e comentadas:
  - `ChatList.vue`, `ChatTypeTabs.vue`, `ConversationCard.vue`, `ConversationHeader.vue`, `ChatListHeader.vue`;
  - `ReplyBottomPanel.vue`;
  - `sidebar/provider.js`.

- **Vocabulário (decisão do PO na US 14):** onde "time" quer dizer o time inteiro, o texto volta a dizer "time", e não "equipe" (19 frases). Departamento continua sendo o nome dos grupos de atendentes.

## Diferenças em relação à história
- A **nota interna** continua no seletor do topo da caixa de resposta, como no Chatwoot, e não como botão no rodapé.
- O botão de **áudio** fica onde já está, não ao lado de "Enviar".
- **Quem pode aceitar:** qualquer atendente com acesso ao canal. A pergunta 1 da história segue em aberto.
- As **mensagens automáticas** do histórico, geradas no servidor, ainda dizem "Conversa…". Os textos do backend ficaram fora da US 14.

## Como testar
1. **Aceitar:** entre como atendente e abra um atendimento em Pendentes. Clique em **Aceitar**: ele vai para Ativos e o card mostra seu nome.
2. **Fila:** clique em **Fila**. O atendimento volta para Pendentes.
3. **Transferir:** clique em **Transferir**, escolha outro atendente e escreva um recado. O atendente muda e o recado aparece como nota interna.
4. **Barra amarela:** mande uma mensagem como cliente pelo widget. O card ganha a barra amarela até alguém responder.
5. **Fechados:** feche um atendimento e abra a aba **Fechados**.
   - O atendimento está lá.
   - O cabeçalho mostra Transferir e Reabrir.
   - **Reabrir** devolve o atendimento às abas de abertos.
6. **Mensagem rápida:** no rodapé, o botão de mensagens rápidas abre a lista, e digitar "/" também.
7. **Iniciar atendimento:** clique no botão do topo da lista e escolha contato e canal.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-21"></a>

## #21 feat(chatclean): CCV2-24 mandatory closing reasons with sale value

- Autor: Bricio29
- Branch: `feature/CCV2-24-closing-reasons` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `fcacc759951468b802852a3fbcdffb441c0cf165`

### Descrição

Fechar um atendimento agora sempre exige um motivo. Ao clicar em Fechar, abre uma janela obrigatória com os motivos cadastrados em Configurações → Motivos de fechamento. Quando o motivo é de venda, a janela pede também o valor, e esse valor vai para o funil de vendas. Assim, o gestor sabe por que cada atendimento terminou e quanto foi vendido.

## Closes
- [CCV2-24](https://chatclean.atlassian.net/browse/CCV2-24) (US 16)

## O que muda
- **Cadastro em Configurações → Motivos de fechamento** (só o administrador):
  - cada motivo tem nome (único na conta), mensagem de fechamento opcional, "perguntar o valor da venda", departamentos (vazio = todos) e ativo;
  - motivo já usado não pode ser excluído, só desativado.
- **Janela obrigatória** em todo fechamento feito por uma pessoa:
  - aparece no botão Fechar (também pelo Alt+E e pela barra de comandos), no menu do card e nas ações em massa;
  - nas ações em massa, o motivo e o valor são escolhidos uma vez para todos.
- **Motivos disponíveis:** o atendente vê os gerais e os dos departamentos dele; o administrador vê todos.
- **Sem nenhum motivo ativo, ninguém fecha** (decisão do PO de 26/10). A janela avisa para pedir o cadastro a um administrador.
- **Valor da venda:** obrigatório quando o motivo pede, em reais, sem negativos.
- **Mensagem de fechamento:** enviada ao cliente antes de fechar.
- **Registro:** cada fechamento grava motivo, quem fechou, quando e o valor. Reabrir e fechar de novo gera outro registro. É a base das US 21 e 22.
- **Funil de vendas**, pela regra aprovada pelo PO:
  - o negócio de origem do atendimento, ou o único negócio aberto do contato, passa para Ganho com o valor da venda;
  - se não houver nenhum dos dois, nasce um negócio Ganho no funil padrão, com quem fechou como responsável;
  - uma conta sem funil padrão fica só com o registro.
- **Validação no servidor:** um fechamento sem motivo, feito por uma pessoa, devolve 422, também pela API. Robôs, automações e o fechamento por inatividade continuam sem motivo.
- **Como entra no Chatwoot:**
  - o servidor é ligado por `config/initializers/chatclean_hooks.rb`, que acrescenta módulos ao `ConversationsController#toggle_status`, ao `BulkActionsController` e ao `BulkActionsJob`, sem editar esses arquivos;
  - na tela, há edições pequenas e comentadas em `ResolveAction.vue`, `ChatList.vue`, `useBulkActions.js`, `Dashboard.vue`, `Sidebar.vue` e `settings.routes.js`;
  - dois testes do Chatwoot passaram a enviar um motivo ao fechar.

## Diferenças em relação à história
- **CA 16.3:** sem motivo ativo, o fechamento fica bloqueado, e não "fecha direto" (decisão do PO, registrada na CCV2-24).
- **Valor zero** é aceito: a CA 16.4 recusa só vazio e negativo.
- **Macros do Chatwoot que fecham** não pedem motivo. A tela de Macros está fora do menu desde a US 14, então nenhuma pode ser criada.
- **Histórico da conversa:** a linha automática "Conversa foi marcada como resolvida por…" continua sem o motivo. O motivo fica no registro, para as US 21 e 22.

## Como testar
1. Como administrador, abra Configurações → Motivos de fechamento:
   - crie "Resolvido";
   - crie "Venda", com "Perguntar o valor da venda" ligado e uma mensagem de fechamento.
2. Abra um atendimento e clique em **Fechar**:
   - escolha "Venda": o campo de valor aparece;
   - informe o valor e confirme.
   O cliente recebe a mensagem, o atendimento vai para Fechados e, no Funil de vendas, o negócio do contato aparece em Ganho com o valor.
3. Feche outro atendimento com "Resolvido": não pede valor.
4. Selecione vários atendimentos na lista e feche em massa: a janela pede o motivo uma vez para todos.
5. Desative todos os motivos e tente fechar: a janela avisa que é preciso cadastrar um motivo, e o botão Fechar fica desabilitado.
6. Ligue um motivo a um departamento e entre como um atendente de fora dele: o motivo não aparece.
7. Tente excluir um motivo já usado: o sistema recusa. Desativá-lo funciona.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-22"></a>

## #22 feat(chatclean): CCV2-23 tabs Ativos, Pendentes and Fechados always with counts

- Autor: Bricio29
- Branch: `feature/CCV2-23-tab-counts` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `e029bb5cb11b29c35fca326bfd5b392918d3675d`

### Descrição

A lista de atendimentos passa a ter só três abas: Ativos, Pendentes e Fechados. Todas mostram a quantidade sempre, mesmo quando é zero. Com a aba Fechados aberta, Ativos e Pendentes continuam mostrando quantos atendimentos abertos há em cada uma.

## Closes
- [CCV2-23](https://chatclean.atlassian.net/browse/CCV2-23) (US 15, ajuste pedido pelo PO)

## O que muda
- **A aba "Todos" sai.** A visão de todos os atendentes continua sendo usada pela aba Fechados.
- **Contadores sempre visíveis:**
  - Ativos conta os abertos com você;
  - Pendentes conta os abertos sem atendente;
  - Fechados conta todos os fechados;
  - os números seguem o canal, o departamento e a etiqueta da lista e se atualizam em tempo real, como os do Chatwoot.
- **Como funciona:** os números do Chatwoot valem para o status em uso. Por isso, `chatclean/conversation/useChatTabCounts.js` busca à parte os abertos e os fechados.

## Diferença a observar
- Sem a aba "Todos", os atendimentos abertos que estão com outros atendentes não aparecem em nenhuma aba. Ainda dá para chegar a eles pelos filtros, pela busca ou pela tela Ao vivo (US 20).

## Como testar
1. Abra Atendimentos: aparecem Ativos, Pendentes e Fechados, todos com número, inclusive zero.
2. Clique em Fechados: Ativos e Pendentes continuam com os números dos abertos.
3. Feche um atendimento: o número de Fechados sobe e o de Ativos desce, sem recarregar a página.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-23"></a>

## #23 feat(chatclean): CCV2-26 agent name on top of the message when the signature is on

- Autor: Bricio29
- Branch: `feature/CCV2-26-agent-signature` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `014e450eade8ae63dde2785d8f2b0e24883a0408`

### Descrição

O atendente pode ligar a assinatura no rodapé do atendimento, e as mensagens passam a sair com o nome dele em negrito na primeira linha. Assim, o cliente sabe com quem está falando. O botão fica verde quando ligado, e a escolha fica guardada por tipo de canal.

## Closes
- [CCV2-26](https://chatclean.atlassian.net/browse/CCV2-26) (US 18)

## O que muda
- **Formato:** "**Nome:**" na primeira linha e o texto na linha seguinte.
  - O nome usado é o de exibição; sem ele, o nome completo.
  - O nome entra só no envio: o campo de digitação mostra apenas o texto.
- **Exceções:**
  - nota interna e mensagem só com arquivo não levam o nome;
  - no Instagram, no Facebook e no TikTok, o nome vai sem negrito, porque esses canais mostrariam os asteriscos.
- **Negrito nos outros canais:** a conversão já é do Chatwoot (WhatsApp `*Nome:*`, Telegram e chat do site em negrito). A quebra de linha funciona em todos.
- **E-mail:** continua com a assinatura do perfil no fim, como no Chatwoot.
- **Preferência:** por atendente e por tipo de canal, guardada nas preferências do usuário pelo próprio Chatwoot. Não há configuração no perfil.
- **Código:** `chatclean/conversation/agentSignature.js`, mais edições pequenas e comentadas em `ReplyBox.vue` e `ReplyBottomPanel.vue`.

## Decisão a confirmar
- **Pergunta 1 da história:** o botão começa **desligado** para um atendente novo, que é o padrão do Chatwoot.

## Como testar
1. Abra um atendimento de chat do site ou de WhatsApp e clique no botão de assinatura do rodapé: ele fica verde.
2. Envie "Bom dia". O cliente recebe o seu nome em negrito na primeira linha e o texto embaixo. O campo de digitação não mostra o nome.
3. Mude para "Nota interna" e envie: a nota sai sem o nome.
4. Abra outro atendimento do mesmo tipo de canal: a assinatura continua ligada. Num canal de outro tipo, ela segue como estava lá.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-24"></a>

## #24 feat(chatclean): CCV2-23 Criar atendimento dialog with phone, channel and team

- Autor: Bricio29
- Branch: `feature/CCV2-23-start-conversation` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `9a9d9cf57be32514e394e9e9185baecde64f4d7e`

### Descrição

O botão "Iniciar atendimento" agora abre a janela "Criar atendimento", no formato da ChatClean atual. Nela o atendente escolhe o contato pelo número (com DDI) ou pela busca, escolhe o canal e o departamento e escreve a mensagem inicial. O atendimento já nasce atribuído a quem iniciou.

## Closes
- [CCV2-23](https://chatclean.atlassian.net/browse/CCV2-23) (US 15, CA 15.6, ajuste pedido pelo PO)

## O que muda
- **Contato:**
  - **número com DDI:** +55 por padrão, escolhido pelo fuso do navegador;
  - **busca:** encontra um contato digitando pelo menos duas letras;
  - **número já cadastrado:** usa o contato existente;
  - **número novo:** cria o contato ao iniciar.
- **Canal e departamento:**
  - para um contato existente, aparecem os canais pelos quais ele pode ser contatado;
  - para um número novo, aparecem os canais por telefone: WhatsApp, SMS e API (o WhatsApp por QR Code do E4 entra como canal de API);
  - quando não há canal possível, a janela avisa;
  - o departamento é opcional.
- **Mensagem inicial:**
  - texto com emojis;
  - no **WhatsApp oficial**, a Meta só aceita um modelo aprovado no primeiro contato, então a janela mostra a escolha do modelo (componente do Chatwoot).
- **Iniciar:** cria o atendimento atribuído a quem iniciou, com o departamento escolhido, e abre o atendimento na tela.
- **Código:** `chatclean/conversation/StartConversationDialog.vue`, reaproveitando a busca de contatos, a criação de contato e a escolha de modelo do WhatsApp do Chatwoot. O `ChatListHeader.vue` passa a abrir essa janela.

## Como testar
1. Em Atendimentos, clique no botão de iniciar atendimento (balão com +): abre "Criar atendimento".
2. Digite duas letras do nome de um contato, escolha o contato, um canal e um departamento, escreva a mensagem e clique em **Iniciar**. O atendimento abre, atribuído a você, no departamento escolhido.
3. Digite um número novo com DDD, escolha um canal por telefone e inicie. O contato é criado com esse número.
4. Num contato sem nenhum canal possível (por exemplo, só chat do site), a janela avisa que não há canal.

No ambiente local há um canal "API Teste" para testar os passos 2 e 3.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-25"></a>

## #25 feat(chatclean): CCV2-25 canned responses by team and user, with attachments

- Autor: Bricio29
- Branch: `feature/CCV2-25-canned-responses` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `82b46fbc3409510cbc6b3578d32d9b09ffc424b4`

### Descrição

As mensagens rápidas agora podem ser de todos, de departamentos ou só de um atendente, e podem levar arquivos. O atendente cria as próprias mensagens rápidas; o administrador compartilha com a conta inteira ou com departamentos. Ao escolher uma mensagem no "/", o texto entra editável e os arquivos entram como anexos removíveis.

## Closes
- [CCV2-25](https://chatclean.atlassian.net/browse/CCV2-25) (US 17)

## O que muda
- **Disponível para:** Todos, Departamentos (um ou mais) ou Só eu.
  - O atendente cria só "Só eu".
  - O administrador escolhe o alcance.
- **Quem vê:**
  - cada atendente vê as de todos, as dos seus departamentos e as suas;
  - o administrador vê todas as compartilhadas e as suas;
  - as "Só eu" dos usuários aparecem para o administrador só com a opção "Exibir mensagens criadas por usuários", na tela de configurações.
- **Quem altera:**
  - o atendente edita e exclui só as suas; nas outras, os botões não aparecem e o servidor recusa;
  - o administrador edita e exclui qualquer uma, sem trocar o dono.
- **Atalho único** entre as compartilhadas e entre as de cada usuário.
- **Anexos:**
  - vários arquivos, até 16 MB no total; acima disso, o formulário avisa e não salva, e o servidor também recusa;
  - ao editar, dá para manter, acrescentar ou remover arquivos.
- **Uso no atendimento:**
  - ao escolher no "/", o texto entra editável e os arquivos entram como anexos removíveis;
  - em canal que não aceita arquivo, só o texto entra;
  - os arquivos são baixados e reenviados, então a mensagem enviada guarda a própria cópia, mesmo se a mensagem rápida for excluída.
- **Saída de departamento:** quem sai de um departamento deixa de ver as mensagens dele na hora. O cache do navegador é renovado quando um membro entra ou sai, ou quando o departamento é apagado.
- **Adicionar a partir de mensagem:** o "Adicionar às mensagens rápidas" do menu da mensagem já existia no Chatwoot e agora tem os campos novos.
- **Mensagens rápidas que já existem:** viram "Todos", como eram no Chatwoot. Era a pergunta 1 da história.
- **Correção de um defeito do E2:**
  - os ganchos da ChatClean e do CRM passam a ser ligados pelo `on_load` do autoloader do Rails;
  - antes, eles carregavam o `Contact` cedo demais, e as mensagens de erro de telefone e e-mail do contato saíam "Translation missing" em desenvolvimento e nos testes.
- **Código:**
  - servidor: `Chatclean::CannedResponseScope` (model) e `Chatclean::CannedResponsesControllerScope` (controller), pelo `chatclean_hooks.rb`, mais a migração `owner_id`, `visibility` e `chatclean_canned_response_teams`;
  - tela: `chatclean/canned/`;
  - edições pequenas e comentadas em `canned_response.rb` (atalho único por dono), nos formulários e na lista de mensagens rápidas, no `CannedResponse.vue`, no `ReplyBox.vue` e na store;
  - dois testes do Chatwoot passaram a usar um administrador para editar e excluir mensagens compartilhadas.

## Como testar
1. **Administrador**, em Configurações → Mensagens rápidas:
   - crie "tabela" disponível para o departamento Comercial, com um PDF;
   - a lista mostra "Departamentos" e o ícone de anexo.
2. **Atendente do Comercial**, num atendimento:
   - digite "/tabela";
   - o texto entra no editor e o PDF entra como anexo, que dá para remover antes de enviar.
3. **Atendente**, em Configurações → Mensagens rápidas:
   - crie uma mensagem: o campo "Disponível para" mostra só "Só eu";
   - nas mensagens compartilhadas não aparecem os botões de editar e excluir.
4. **Fora do departamento:** tire o atendente do Comercial. Ele deixa de ver "tabela" no "/".
5. **Administrador:** ligue "Exibir mensagens criadas por usuários". Aparecem as "Só eu" dos atendentes, com o nome do dono.
6. **Limite de 16 MB:** tente salvar anexos que somem mais de 16 MB. O formulário avisa e não salva.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-26"></a>

## #26 feat(chatclean): CCV2-27 account business hours and holidays

- Autor: Bricio29
- Branch: `feature/CCV2-27-account-hours` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `f91d43270ad13f70a261909a785109936103afc8`

### Descrição

O administrador agora pode definir um horário de atendimento único para todos os canais e cadastrar os feriados. No feriado, quem escreve recebe a mensagem do feriado, sem precisar configurar canal por canal.

## Closes
- [CCV2-27](https://chatclean.atlassian.net/browse/CCV2-27) (US 19)

## O que muda
- **Configurações → Horário e feriados** (administrador), com duas abas.
- **Horário de atendimento:**
  - **por canal** (padrão, como no Chatwoot) ou **por conta**;
  - em "por conta": ligado/desligado, fuso, mensagem de ausência e os sete dias ("Fechado", "Aberto 24h" ou um intervalo);
  - o servidor recusa fuso inválido, dia faltando, fechamento antes da abertura e "Fechado" junto com "Aberto 24h".
- **Efeito nos canais:**
  - em "por conta", o horário é copiado para todos os canais, e os canais novos já nascem com ele;
  - a aba "Horário de funcionamento" de cada canal mostra "Este canal segue o horário de atendimento da conta", com link;
  - o servidor recusa mudança de horário pelo canal enquanto a conta manda;
  - ao voltar para "por canal", cada canal fica com o último horário da conta.
- **Feriados:**
  - data, nome e mensagem opcional; um por data; lista por ano;
  - "Importar feriados nacionais de <ano>" traz os 9 de data fixa e a Sexta-feira Santa do ano escolhido, sem duplicar nem sobrescrever;
  - isso responde a pergunta 1 da história: o administrador escolhe o ano.
- **No feriado:**
  - o canal com horário ligado fica fora do horário o dia todo, no fuso do canal;
  - ele responde com a mensagem do feriado ou com a padrão: "Hoje é feriado. Nosso atendimento está suspenso e retornaremos no próximo dia útil.";
  - canal sem horário ligado não é afetado.
- **Permissões:** todos consultam, pela API; só o administrador altera.
- **Código:**
  - `Chatclean::AccountSchedule`, `Chatclean::Holiday` e `Chatclean::InboxSchedule` (gancho no `Inbox`, pelo `chatclean_hooks.rb`);
  - controllers `working_schedules` e `holidays`;
  - tela em `settings/businessHours/`;
  - edições pequenas e comentadas no `OutOfOffice` e no `HookExecutionService` (mensagem do feriado) e no `WeeklyAvailability.vue` (aviso no canal).

## Como testar
1. Em Configurações → Horário e feriados:
   - escolha "Conta", ative o horário, escreva a mensagem e ajuste os dias;
   - salve;
   - abra um canal: a aba de horário avisa que segue a conta.
2. Na aba Feriados:
   - clique em "Importar feriados nacionais": aparecem 10 feriados;
   - importe de novo: nada se repete.
3. Cadastre um feriado para hoje, com uma mensagem própria. Mande uma mensagem como cliente por um canal com horário ligado: chega a mensagem do feriado.
4. Volte para "Canal": cada canal mantém o último horário da conta e volta a ser editável.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-27"></a>

## #27 feat(chatclean): CCV2-29 translation sweep and Portuguese as the system default language

- Autor: Bricio29
- Branch: `feature/CCV2-29-translation-sweep` → `main`
- Aberto em 2026-10-26; mergeado em 2026-10-26, commit `9b0fdfbeea646b3799732040e32a56320336f86a`

### Descrição

O painel e as mensagens do sistema passam a aparecer em português nos pontos que ainda estavam em inglês, com o vocabulário da ChatClean (Atendimento, Canal, Departamento, Atendente, Fechar). As mensagens automáticas do histórico, como o fechamento por inatividade, também saem em português.

## Closes
- [CCV2-29](https://chatclean.atlassian.net/browse/CCV2-29) (US 14, revisão de tradução pedida pelo PO)

## O que muda
- **Painel:** 879 textos traduzidos ou refeitos no `pt_BR/chatcleanVocabulary.json`:
  - 678 não tinham tradução em português e apareciam em inglês: integrações, relatórios, canais, envios, empresas, configurações e outros;
  - cerca de 200 estavam iguais ao inglês;
  - alguns tinham tradução ruim, como "Permitir a disponibilidade de negócios" no horário do canal.
- **Servidor:** novo `config/locales/pt_BR_chatclean.yml`, que carrega depois do `pt_BR.yml` do Chatwoot:
  - 172 textos que faltavam em português: e-mails de acesso e senha, erros, avisos e paginação;
  - 93 textos reescritos no vocabulário, como "O atendimento foi fechado por Ana" em vez de "A conversa foi marcada como resolvida", em notificações, relatórios exportados e integrações;
  - "Painel de Aplicativos" passa a ser "Plugins".
- **Idioma padrão do sistema** (`config/initializers/chatclean_locale.rb`):
  - segue o `DEFAULT_LOCALE`;
  - antes, os textos gerados fora de uma requisição (jobs, como o fechamento automático por inatividade) saíam em inglês mesmo com a conta em português;
  - sem a variável (testes), continua o inglês;
  - na produção, o que faltar em português cai no inglês.
- **Produção:** `DEFAULT_LOCALE=pt_BR` entra no `env.production.example`, ou seja, vai para o SSM no primeiro deploy.
- **Teste de vocabulário:**
  - passa a aceitar frases que existem nos textos do Chatwoot em inglês ou em português;
  - lista como exceção 8 textos que usam "time" no sentido do time inteiro.
- **Escolhas de tradução a conferir:**
  - "Feedback" virou "Avaliação";
  - "Guardrails" do Captain virou "Restrições";
  - "workspace" do Shopify virou "conta".

## Como testar
1. Com o painel em português, abra Configurações → Integrações, Dashboards, Canais e Envios: os textos aparecem em português.
2. Feche um atendimento: o histórico mostra "O atendimento foi fechado por …".
3. Com o fechamento automático por inatividade ligado na conta, o histórico mostra "O atendimento foi fechado pelo sistema…" em português.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

<a id="pr-28"></a>

## #28 chore(release): CCV2-37 keep only Chatwoot with ChatClean logos and name on main

- Autor: Bricio29
- Branch: `chore/CCV2-37-main-chatwoot-original` → `main`
- Aberto em 2026-10-27; mergeado em 2026-10-27, commit `fe78c97825cc24cf6024d20ce0122d98e246ceb2`

### Descrição

A produção passa a rodar o Chatwoot original, que já roda em produção em outras empresas, só com os logos e o nome da ChatClean. As funcionalidades novas (CRM, tela de atendimento no padrão ChatClean, motivos de fechamento, assinatura, mensagens rápidas, horário e feriados, vocabulário e a identidade visual completa) ficam no branch `chatclean-features` até serem validadas. É uma orientação do CTO que mentora o PO.

## Closes
- [CCV2-37](https://chatclean.atlassian.net/browse/CCV2-37)

## O que muda
- **Branch `chatclean-features`:** já publicado com a `main` como estava antes deste PR (commit 9b0fdfbeea). Nada se perde, e o desenvolvimento das funcionalidades continua lá.
- **A `main` fica com o Chatwoot 4.18 original e só:**
  - **Ambiente local, CI e infraestrutura da AWS:** `.chatclean/`, `docker-compose.override.yaml`, verificação do Redis no boot, workflows de CI e de deploy, e a quarentena de testes instáveis.
  - **Logos e nome ChatClean:**
    - a tarefa `chatclean:branding` grava nome, logos e links na configuração da instalação;
    - o painel, o login, o menu e os e-mails do Chatwoot já leem essa configuração;
    - no Super Admin e na configuração inicial, o `ChatcleanBrand` mostra o logo e o nome.
  - **Correções para rodar sem a parte Enterprise:**
    - a tela de usuários só busca papéis customizados quando há Enterprise;
    - a configuração inicial não tem "receber novidades", que enviava ao Chatwoot a empresa, o nome e o e-mail do primeiro administrador.
- **Volta ao original do Chatwoot:** cores (o verde da marca sai), menu lateral, Super Admin (sem seletor de idioma nem menu recolhível), textos e idioma padrão.
- **CI:** saem os jobs do CRM. O CI passa a rodar também em PRs para `chatclean-features`.
- **Como as funcionalidades voltam:** cada uma volta para a `main` por PR. Como a retirada é este commit de reversão, a volta começa com `git revert` dele.
- **Documentação:** o `.chatclean/README.md` explica o papel de cada branch.

## Como testar
1. Abra o login: aparecem o logo e o nome ChatClean ("Entrar no ChatClean"), com as cores do Chatwoot.
2. Entre: o painel é o do Chatwoot (Conversas, Caixa de Entrada, Times), com o ícone ChatClean no menu.
3. Abra o Super Admin: aparecem o logo e o nome ChatClean.
4. Troque para o branch `chatclean-features`: todas as funcionalidades continuam lá.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
