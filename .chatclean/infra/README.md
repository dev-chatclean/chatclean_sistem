# Infraestrutura de produção na AWS

Máquina única em São Paulo (sa-east-1) para `https://chat.chatclean.com.br` (US 10, CCV2-19). Tudo
fica na stack CloudFormation `chatclean-base`, descrita em `chatclean-base.yaml` e aplicada pela AWS
CLI com `deploy-base`. O deploy da aplicação nessa máquina está em `../deploy/README.md` (CCV2-20).

## O que a stack cria

| Recurso | Configuração |
|---|---|
| EC2 `chatclean-production` | `t3.large` (2 vCPU, 8 GB, x86), Ubuntu 24.04 LTS, disco gp3 de 50 GB criptografado |
| Disco | `DeleteOnTermination: false`: o banco e o Redis moram nele e sobrevivem se a máquina for encerrada |
| Proteção | proteção contra encerramento ligada; máquina, IP e ECR ficam mesmo se a stack for apagada |
| Preparação (primeiro boot) | Docker Engine e Compose, AWS CLI, swap de 4 GB, `somaxconn=1024` e `overcommit_memory=1` (Redis), pasta `/opt/chatclean` |
| Elastic IP | IP fixo da máquina, que vai no registro A da Hostinger |
| Security Group `chatclean-web` | entrada só em 80 e 443. Sem porta 22 e sem 5432/6379 |
| Acesso ao terminal | SSM Session Manager, sem chave SSH |
| Role da máquina | SSM, leitura do ECR e dos parâmetros em `/chatclean/production` |
| ECR `chatclean` | imagens imutáveis, varredura de vulnerabilidades e as 20 mais recentes guardadas |
| OIDC do GitHub + role `chatclean-github-deploy` | o workflow de deploy entra na AWS sem chave fixa, só a partir da `main` |
| Bucket `chatclean-attachments-<conta>` | anexos das conversas (CCV2-21): privado, criptografado (SSE-S3); a máquina acessa pela role, sem chave fixa |
| Bucket `chatclean-backups-<conta>` | dumps diários do banco em `database/`, apagados depois de 30 dias |
| Snapshots (Data Lifecycle Manager) | snapshot diário do disco às 03:30 de Brasília, guardando os 7 últimos |
| Tópico SNS `chatclean-alerts` | alertas por e-mail para `AlertEmail` (padrão `desenvolvimento@chatclean.com.br`) |

O Docker sobe no boot pelo systemd. Caddy, rails, sidekiq, Postgres e Redis são containers com
`restart: always`, então voltam junto depois de um reboot.

Custo aproximado: US$ 115/mês (máquina ~US$ 98, disco ~US$ 8, IP ~US$ 4, snapshots e S3 alguns dólares,
crescendo com os anexos). Confira na calculadora da AWS antes de criar.

## Criar

Antes: créditos aprovados e a sessão da AWS aberta (`aws sso login --profile ChatClean`).

```sh
.chatclean/infra/deploy-base --dry-run   # mostra o que será criado e não cria nada
.chatclean/infra/deploy-base             # cria (ou atualiza) e mostra as saídas
```

Saídas:

| Saída | Para quê |
|---|---|
| `PublicIp` | registro A de `chat` na Hostinger |
| `InstanceId` | variável `CHATCLEAN_INSTANCE_ID` do GitHub |
| `DeployRoleArn` | variável `AWS_DEPLOY_ROLE_ARN` do GitHub |
| `AttachmentsBucketName` | parâmetro `S3_BUCKET_NAME` em `/chatclean/production` |

A AWS manda um e-mail para o `AlertEmail` pedindo para confirmar a assinatura dos alertas. **Clique no
link**, senão nenhum alerta chega. Para outro endereço, crie com
`aws cloudformation deploy ... --parameter-overrides AlertEmail=<email>` ou troque depois no console do SNS.

A preparação da máquina leva alguns minutos depois que a stack termina. Para conferir:

```sh
aws ssm start-session --profile ChatClean --region sa-east-1 --target <InstanceId>
# na máquina:
cloud-init status --wait && docker compose version && swapon --show && sysctl net.core.somaxconn vm.overcommit_memory
```

O `start-session` precisa do plugin do Session Manager no Mac: `brew install --cask session-manager-plugin`.

## DNS na Hostinger

Registro `A` com nome `chat` apontando para o `PublicIp`, TTL 300. Ele pode ser criado pelo conector da
Hostinger, **sempre com aprovação do PO antes**. Para conferir: `dig +short chat.chatclean.com.br`.

## Testar o HTTPS antes da aplicação

Com o DNS propagado, suba um Caddy de teste na máquina (pelo `start-session`). Ele emite o certificado
do Let's Encrypt e serve a página padrão:

```sh
sudo docker run -d --name https-test -p 80:80 -p 443:443 caddy:2.10-alpine \
  caddy file-server --root /usr/share/caddy --domain chat.chatclean.com.br
```

No Mac, `curl -I https://chat.chatclean.com.br` deve responder 200 com certificado válido. Depois remova
o teste com `sudo docker rm -f https-test`, porque ele ocupa as portas 80 e 443 do Caddy de produção.

Se o DNS ainda não tiver propagado, o Caddy tenta emitir de novo sozinho, com intervalos crescentes.

## Depois

1. Parâmetros em `/chatclean/production/` e variáveis do GitHub: ver "Primeiro deploy" em `../deploy/README.md`.
   Backup e recuperação: ver "Backup e recuperação" no mesmo arquivo.
2. Teste de reboot: `aws ec2 reboot-instances --instance-ids <InstanceId>`. A máquina volta com o mesmo IP
   e os containers sobem sozinhos.

## Atualizar ou desfazer

- **Atualizar:** edite `chatclean-base.yaml` e rode `deploy-base` de novo (comece pelo `--dry-run`). O AMI
  fica o da criação, porque um AMI novo recriaria a máquina. Se o dry-run mostrar `Replacement: True` na
  `Instance`, pare e reveja a mudança.
- **Desmontar tudo** (só com o PO de acordo, porque apaga o banco):
  1. desligue a proteção contra encerramento e encerre a máquina;
  2. apague a stack: ela remove o Security Group, as roles e o OIDC;
  3. apague à mão o que a stack mantém (`DeletionPolicy: Retain`): o disco, o Elastic IP, o ECR e os dois buckets.
