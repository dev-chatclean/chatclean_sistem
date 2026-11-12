# Instalação do ChatClean em produção

Produção numa máquina na AWS, no Norte da Virgínia (`us-east-1`), em `https://chat.chatclean.com.br` (CCV2-39).
Desde 12/11/2026 (CCV2-52), a máquina roda **o código da `main` deste repositório**, no lugar do Chatwoot oficial,
na mesma forma reduzida da [documentação do Chatwoot](https://developers.chatwoot.com/self-hosted/deployment/linux-vm):
uma zona e uma máquina, sem load balancer, RDS, ElastiCache, NAT nem bastion. Banco, Redis e HTTPS ficam na própria
máquina. A infraestrutura está em `../infra/README.md`.

A pasta do Chatwoot (`/home/chatwoot/chatwoot`) segue a `main` pelo remote `chatclean`, lido com uma chave só de leitura
(`~chatwoot/.ssh/chatclean_deploy`, cadastrada nas deploy keys do repositório). **Nunca rode `cwctl --upgrade`:** ele
traria o Chatwoot oficial de volta por cima do nosso código. As versões novas do Chatwoot entram pela `main`
(`../bin/sync-upstream`) e chegam à produção pelo `deploy-app`.

Além do código, o `server/setup` cuida da edição gratuita (`DISABLE_ENTERPRISE=true`), dos anexos no S3, do e-mail
pelo SES e do backup diário do banco.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `deploy-app` | No Mac: leva a `main` para a produção (snapshot, backup, código, front, migrações, reinício e marca) |
| `push-ops` | No Mac: envia `server/` para a máquina (pelo S3 e pelo SSM) e roda o `setup` |
| `server/setup` | Na máquina: completa o `.env`, aplica a marca (`rails chatclean:branding`), instala o backup e reinicia o Chatwoot |
| `server/backup-db` | Backup diário do banco para o S3, com alerta por e-mail se falhar |
| `restore-check.sh` + `count-rows.sql` | No Mac: restaura um dump num Postgres temporário e conta as linhas de cada tabela |

## Versão do Chatwoot

A produção roda a versão do Chatwoot que está na `main` (em 12/11/2026, a v4.19.1). Para uma versão nova: trazer a
tag para a `dev` e a `main` com o CI verde, e então rodar o `deploy-app`.

## Primeira instalação

Antes: a infraestrutura criada (`../infra/README.md`), o SES configurado e as credenciais SMTP gravadas
(`../infra/ses-smtp-credentials`).

1. **DNS na Hostinger** (com aprovação do PO): registro `A` `chat` → `52.3.27.21`, TTL 300. O Let's Encrypt
   só emite o certificado com o DNS apontando para a máquina. Confira com `dig +short chat.chatclean.com.br`.
2. **Entrar na máquina** (sem SSH):

   ```sh
   aws ssm start-session --profile ChatClean --region us-east-1 --target <InstanceId>
   sudo -i
   cloud-init status --wait     # a preparação do primeiro boot precisa ter terminado
   ```

3. **Instalar o Chatwoot**, como na documentação (cerca de 20 minutos):

   ```sh
   wget https://get.chatwoot.app/linux/install.sh
   chmod 755 install.sh
   ./install.sh --install
   ```

   Respostas:

   | Pergunta | Resposta |
   |---|---|
   | Would you like to configure a domain and SSL for Chatwoot? | `yes` |
   | Enter the domain/subdomain for Chatwoot | `chat.chatclean.com.br` |
   | Enter an email address for LetsEncrypt | `desenvolvimento@chatclean.com.br` |
   | Do you wish to proceed? | `yes` |
   | Would you like to install Postgres and Redis? | `yes` |

   O script instala Ruby, Node, PostgreSQL 16 com pgvector, Redis, nginx e o certificado, prepara o banco e sobe o
   Chatwoot como serviço (`chatwoot.target`). O log fica em `/var/log/chatwoot-setup.log`.
4. **Configuração da ChatClean**, no Mac:

   ```sh
   .chatclean/deploy/push-ops
   ```

   Ele termina com `Status: Success` e mostra `active` para o `chatwoot.target`.
5. **Configuração inicial**, no navegador, em `https://chat.chatclean.com.br`: crie a conta e o primeiro
   administrador. **Desmarque "receber novidades"**: marcada, ela envia ao Chatwoot a empresa, o nome e o e-mail do
   administrador.
6. **Conferir:**
   - a tela de login mostra o logo e o nome ChatClean;
   - um anexo enviado numa conversa aparece no bucket `chatclean-attachments-<conta>`;
   - o convite de um agente chega por e-mail;
   - `sudo systemctl start chatclean-backup` cria um arquivo em `s3://chatclean-backups-<conta>/database/`.

## Levar a `main` para a produção

No Mac, com a sessão AWS ativa (`aws sso login --profile ChatClean`) e a `main` com o CI verde:

```sh
.chatclean/deploy/deploy-app
```

O script:
1. tira um snapshot do disco e espera terminar;
2. roda o backup do banco para o S3;
3. na máquina, com o sistema no ar: `git checkout` da `main`, `bundle install`, `pnpm install`, compila o front e roda
   as migrações (em 12/11/2026, 3 minutos);
4. reinicia o Chatwoot (1 a 2 minutos fora do ar) e reaplica a marca (`rails chatclean:branding`);
5. confere o login e conta os erros 500 desde o reinício.

Durante os segundos antes do reinício, o processo antigo pode dar erro 500 em telas que mudaram, porque o código novo
já está na pasta. Some quando o processo novo sobe.

Rode o `push-ops` só quando mudar algo em `server/` (o `.env`, o backup).

### Voltar um deploy

- **Só o código** (as migrações do CRM só acrescentam tabelas e colunas): na máquina, como `chatwoot`,
  `git checkout -B main <commit anterior>` (o `deploy-app` mostra o commit anterior), compile o front e reinicie.
- **Tudo, inclusive o banco:** troque o disco da máquina por um volume criado do snapshot que o `deploy-app` mostrou
  no fim (veja "Recuperar a máquina inteira", abaixo). Perde-se o que entrou depois do snapshot.

## Comandos do dia a dia (na máquina)

| Para quê | Comando |
|---|---|
| Reiniciar | `sudo cwctl --restart` |
| Logs do Chatwoot | `sudo cwctl --logs web` ou `sudo cwctl --logs worker` |
| Console do Rails | `sudo cwctl --console` |
| Versão | `sudo -u chatwoot git -C /home/chatwoot/chatwoot log --oneline -1` |
| Renovar o certificado | automático (timer do `certbot`); para conferir: `sudo certbot renew --dry-run` |

## Backup e recuperação

| O quê | Como | Guarda |
|---|---|---|
| Banco | `server/backup-db` às 03:00 de Brasília (timer `chatclean-backup`) → `s3://chatclean-backups-<conta>/database/` | 30 dias |
| Disco inteiro | snapshot diário às 03:30 de Brasília (Data Lifecycle Manager) | 7 dias |
| Anexos | bucket `chatclean-attachments-<conta>` | sem prazo |

Se o backup falhar, ou se o disco tiver menos de 10 GB livres, chega um e-mail pelo `chatclean-alerts`. O log fica em
`/var/log/chatclean_backup.log`. Backup manual: `sudo /opt/chatclean/backup-db`.

**Testar a restauração** (no Mac, com Docker):

```sh
aws s3 cp --profile ChatClean s3://chatclean-backups-<conta>/database/<arquivo> .
.chatclean/deploy/restore-check.sh <arquivo> > restaurado.txt
```

Na máquina, conte as linhas do banco de produção e compare com `restaurado.txt`:

```sh
sudo -u postgres psql -At -F' ' chatwoot_production < count-rows.sql
```

**Recuperar a máquina inteira:** crie um volume a partir do snapshot mais recente, troque o disco da máquina por ele
(com a máquina parada) e ligue de novo. O IP fixo continua o mesmo.

## Limitações conhecidas

- O Super Admin e a tela da configuração inicial mostram o logo e o nome do Chatwoot, porque estão fixos no código
  oficial. Painel, login e widget mostram os da ChatClean.
- A tela de agentes pede os papéis personalizados, que só existem na edição paga. Na edição gratuita, esse pedido
  devolve erro no console do navegador, e a tela funciona normalmente.
