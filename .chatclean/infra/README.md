# Infraestrutura de produção na AWS

A arquitetura de referência do Chatwoot na AWS ([documentação](https://developers.chatwoot.com/self-hosted/deployment/aws))
reduzida a uma zona no Norte da Virgínia (`us-east-1`), por recomendação do CTO (CCV2-39). Diagrama:
https://claude.ai/artifact/Y1mTfe2KL71wDesGwyJ7vL

Criada em 28/10/2026, a parte de rede, máquina, S3, SNS e IAM pelo console (pelo [guia](https://claude.ai/artifact/Dr4NjB6addpd6sKPhgZuAq))
e o resto pela AWS CLI. Não há stack: `chatclean-base.yaml` descreve a configuração e os nomes, que os scripts
procuram. A instalação do Chatwoot nessa máquina está em `../deploy/README.md`.

## O que existe

| Recurso | Configuração |
|---|---|
| VPC `chatclean-vpc` | `10.0.0.0/16`, com internet gateway |
| Sub-rede `chatclean-public-1` | `10.0.0.0/24` na zona `us-east-1a`, pública, rota padrão para o internet gateway |
| EC2 `chatclean-production` | `t3.large` (2 vCPU, 8 GB, x86), Ubuntu 24.04 LTS, disco gp3 de 60 GB criptografado |
| Disco | `DeleteOnTermination: false`: banco e Redis moram nele e sobrevivem se a máquina for encerrada |
| Proteção | proteção contra encerramento ligada |
| Preparação (primeiro boot) | AWS CLI, swap de 4 GB, `somaxconn=1024` e `overcommit_memory=1` (Redis), pasta `/opt/chatclean`, CloudWatch Agent |
| Elastic IP | `52.3.27.21`, IP fixo da máquina, que vai no registro A da Hostinger |
| Security Group `chatclean-web` | entrada só em 80 e 443. Sem porta 22 e sem 3000, 5432 e 6379 |
| Acesso ao terminal | SSM Session Manager, sem chave SSH |
| Role da máquina | SSM, CloudWatch, anexos no S3, envio dos backups, leitura de `ops/` e dos parâmetros em `/chatclean/production` |
| Bucket `chatclean-attachments-<conta>` | anexos das conversas: privado, criptografado (SSE-S3); a máquina acessa pela role, sem chave fixa |
| Bucket `chatclean-backups-<conta>` | dumps diários do banco em `database/` (apagados depois de 30 dias) e os scripts e logos do `push-ops` em `ops/` |
| Snapshots (Data Lifecycle Manager) | snapshot diário do disco às 03:30 de Brasília, guardando os 7 últimos |
| Tópico SNS `chatclean-alerts` | alertas por e-mail para `AlertEmail` (padrão `desenvolvimento@chatclean.com.br`) |
| SES `chatclean.com.br` | e-mail transacional: domínio verificado por DKIM e MAIL FROM `bounce.chatclean.com.br` |
| Usuário IAM `chatclean-ses-smtp` | só envia e-mail pelo SES; a chave dele vira a senha SMTP (`ses-smtp-credentials`) |
| CloudWatch Agent | memória e disco da máquina, e o log de acesso HTTPS do nginx em `/chatclean/nginx` (30 dias) |
| Alarmes (e-mail pelo `chatclean-alerts`) | CPU > 85% por 10 min, memória > 90% por 10 min, disco > 80%, mais de 20 erros 5xx em 5 min, máquina sem resposta e falha de host (a máquina é recuperada sozinha, com o mesmo disco e IP) |
| Orçamento `chatclean-mensal` | US$ 150/mês, com e-mail em 85%, 100% e na previsão de 100% |

**Fora desta versão**, da arquitetura de referência:
- segunda zona;
- sub-redes privadas e NAT gateways;
- bastions;
- load balancer;
- RDS e ElastiCache;
- Auto Scaling.

Dá para ligar cada um depois, sem refazer a máquina. O primeiro passo seria mover o banco para o RDS.

Custo aproximado: US$ 75 a 85 por mês. A máquina custa cerca de US$ 61, o disco cerca de US$ 5 e o IP fixo cerca de
US$ 4. Snapshots, S3, CloudWatch e SES somam alguns dólares, crescendo com o uso. Confira na calculadora da AWS antes
de criar.

## Conferir a máquina

```sh
aws ssm start-session --profile ChatClean --region us-east-1 --target <InstanceId>
# na máquina:
cloud-init status --wait && aws --version && swapon --show && sysctl net.core.somaxconn vm.overcommit_memory
```

O `start-session` precisa do plugin do Session Manager no Mac: `brew install --cask session-manager-plugin`. O
`InstanceId` aparece no console do EC2 ou em
`aws ec2 describe-instances --filters Name=tag:Name,Values=chatclean-production`.

## DNS na Hostinger

Registro `A` com nome `chat` apontando para `52.3.27.21`, TTL 300. Ele pode ser criado pelo conector da Hostinger,
**sempre com aprovação do PO antes**. Para conferir: `dig +short chat.chatclean.com.br`.

## E-mail pelo SES

O domínio já tem e-mail na Hostinger (MX e SPF `include:_spf.mail.hostinger.com`), que continua igual. O SES usa o
subdomínio `bounce.chatclean.com.br` como MAIL FROM, com SPF próprio, e assina com DKIM. Assim o e-mail passa no
DMARC sem mexer no SPF da raiz.

1. **Registros na Hostinger** (com aprovação do PO):

   | Tipo | Nome | Valor |
   |---|---|---|
   | CNAME | `<token>._domainkey`, um para cada um dos três tokens de `aws sesv2 get-email-identity` | `<token>.dkim.amazonses.com` |
   | MX | `bounce` | `10 feedback-smtp.us-east-1.amazonses.com` |
   | TXT | `bounce` | `v=spf1 include:amazonses.com ~all` |
   | TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:desenvolvimento@chatclean.com.br` |

   Em 23/10/2026 não havia DMARC. Se aparecer um, mude o existente em vez de criar outro. Depois de algumas semanas
   de relatórios sem problema, o DMARC pode passar a `p=quarantine`.
2. **Conferir:** `aws sesv2 get-email-identity --email-identity chatclean.com.br --profile ChatClean --region us-east-1`
   deve mostrar `VerifiedForSendingStatus: true` e o MAIL FROM com `SUCCESS`.
3. **Credenciais SMTP:** `.chatclean/infra/ses-smtp-credentials` grava `SMTP_USERNAME` e `SMTP_PASSWORD` no Parameter
   Store, sem mostrar a senha. O `setup` copia as duas para o `.env` do Chatwoot.
4. **Saída da sandbox:** até a AWS aprovar, o SES só entrega para endereços verificados um a um
   (`aws sesv2 create-email-identity --email-identity <email>`). O pedido:

   ```sh
   aws sesv2 put-account-details --profile ChatClean --region us-east-1 \
     --production-access-enabled --mail-type TRANSACTIONAL --contact-language EN \
     --website-url https://chatclean.com.br \
     --additional-contact-email-addresses desenvolvimento@chatclean.com.br \
     --use-case-description "ChatClean is a customer service platform (shared inbox and CRM) used internally by our team. SES sends only transactional e-mails to our own users: account invitations, password resets and conversation notifications. Recipients are users created by an administrator; there are no marketing lists. Bounces and complaints are handled by SES suppression."
   ```

   A resposta costuma vir em até um dia útil, por e-mail.

## Depois

1. Instalação do Chatwoot: `../deploy/README.md`.
2. Teste de reboot: `aws ec2 reboot-instances --instance-ids <InstanceId>`. A máquina volta com o mesmo IP, e o
   Chatwoot, o Postgres, o Redis e o nginx sobem sozinhos pelo systemd.

## Mudar ou desfazer

- **Mudar:** pelo console ou pela AWS CLI, mantendo os nomes, e atualize `chatclean-base.yaml` para ele continuar
  descrevendo o que existe.
- **Desmontar tudo** (só com o PO de acordo, porque apaga o banco): desligue a proteção contra encerramento, encerre
  a máquina e apague o disco, o Elastic IP, os buckets, os alarmes, a política de snapshots, a VPC e o resto da
  tabela acima.
