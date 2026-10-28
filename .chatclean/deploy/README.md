# Instalação do ChatClean em produção

Produção numa máquina na AWS, no Norte da Virgínia (`us-east-1`), em `https://chat.chatclean.com.br` (CCV2-39).
A máquina roda o **Chatwoot oficial**, instalado como na documentação do Chatwoot
([AWS](https://developers.chatwoot.com/self-hosted/deployment/aws) e
[Linux VM](https://developers.chatwoot.com/self-hosted/deployment/linux-vm)), numa forma reduzida: uma zona,
uma máquina, sem load balancer, RDS, ElastiCache, NAT nem bastion. Banco, Redis e HTTPS ficam na própria máquina,
como o `install.sh` faz. A infraestrutura está em `../infra/README.md`.

O código deste repositório **não** vai para a produção. Da ChatClean só entram:
- a edição gratuita (`DISABLE_ENTERPRISE=true`);
- anexos no S3 e e-mail pelo SES;
- nome e logos;
- o backup diário do banco.

Tudo isso é feito por `server/setup`.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `push-ops` | No Mac: envia `server/` e os logos para a máquina (pelo S3 e pelo SSM) e roda o `setup` |
| `server/setup` | Na máquina: completa o `.env`, aplica a marca, instala o backup e reinicia o Chatwoot |
| `server/branding.rb` | Nome, logos e links da ChatClean nas configurações do Chatwoot |
| `server/backup-db` | Backup diário do banco para o S3, com alerta por e-mail se falhar |
| `restore-check.sh` + `count-rows.sql` | No Mac: restaura um dump num Postgres temporário e conta as linhas de cada tabela |

## Versão do Chatwoot

A instalação e as atualizações seguem a documentação: `install.sh --install` e `cwctl --upgrade` levam à última
versão estável do Chatwoot (em 28/10/2026, a v4.19.1). Anote a versão instalada (`sudo cwctl --version`) no Jira a
cada instalação ou atualização.

## Primeira instalação

Antes: créditos da AWS liberados, a stack criada (`../infra/README.md`), o SES configurado e as credenciais SMTP
gravadas (`../infra/ses-smtp-credentials`).

1. **DNS na Hostinger** (com aprovação do PO): registro `A` `chat` → `PublicIp` da stack, TTL 300. O Let's Encrypt
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

## Atualizar o Chatwoot

Como na documentação: atualiza pela `cwctl`, que leva à última versão estável e roda as migrações. Na máquina:

```sh
sudo cwctl --upgrade
```

Depois, no Mac, `.chatclean/deploy/push-ops`, para aplicar a marca de novo e reiniciar.

A `cwctl` para se encontrar mudança nos arquivos do Chatwoot ("Custom code changes detected"). O `setup` não
altera nenhum arquivo versionado: os logos ficam em `public/brand-assets/chatclean/` e o script da marca em
`tmp/`, que o repositório do Chatwoot não tem.

## Comandos do dia a dia (na máquina)

| Para quê | Comando |
|---|---|
| Reiniciar | `sudo cwctl --restart` |
| Logs do Chatwoot | `sudo cwctl --logs web` ou `sudo cwctl --logs worker` |
| Console do Rails | `sudo cwctl --console` |
| Versão | `sudo cwctl --version` |
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
