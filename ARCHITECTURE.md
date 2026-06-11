# SQS Stack — Architecture

## Overview

Stack que provisiona uma fila SQS **Standard** com Dead-Letter Queue (DLQ) integrada, seguindo as melhores práticas de segurança e operação definidas pela AWS. Parametrizada via `environments/*.tfvars` para deploy em **dev**, **staging** e **prod** sem alteração de código.

---

## Diagrama

```
Producer (Lambda / S3 / API)
          │
          │ sqs:SendMessage (HTTPS only)
          ▼
┌─────────────────────────────────────────────────────┐
│  SQS Standard Queue                                 │
│  {project}-{env}-{suffix}                           │
│                                                     │
│  ├── SSE-SQS (AES-256) ou SSE-KMS                   │
│  ├── Long polling   (20s)                           │
│  ├── Visibility timeout configurável                │
│  ├── Retenção de mensagens configurável             │
│  └── Queue Policy: DenyNonSSL                       │
│                                                     │
│  maxReceiveCount = N                                │
└────────────────────┬────────────────────────────────┘
                     │ mensagem recebida N+ vezes
                     │ sem ACK (delete)
                     ▼
┌─────────────────────────────────────────────────────┐
│  Dead-Letter Queue (DLQ)                            │
│  {project}-{env}-{suffix}-dlq                       │
│                                                     │
│  ├── Retenção: 14 dias (máx)                        │
│  ├── Mesma criptografia da fila principal           │
│  ├── Redrive Allow: somente da fila principal       │
│  └── Queue Policy: DenyNonSSL                       │
└─────────────────────────────────────────────────────┘
          │
          ▼
  Alarme / reprocessamento manual
```

---

## Recursos

| Recurso | Nome gerado | Descrição |
|---|---|---|
| `aws_sqs_queue.this` | `{project}-{env}-{suffix}` | Fila principal Standard. |
| `aws_sqs_queue.dlq` | `{project}-{env}-{suffix}-dlq` | Dead-Letter Queue — recebe mensagens que falharam `maxReceiveCount` vezes. |
| `aws_sqs_queue_redrive_policy.this` | — | Liga a fila principal à DLQ com o `maxReceiveCount`. |
| `aws_sqs_queue_redrive_allow_policy.dlq` | — | Restringe o redrive da DLQ a origem apenas da fila principal. |
| `aws_sqs_queue_policy.this` | — | Nega toda comunicação não-HTTPS com a fila principal. |
| `aws_sqs_queue_policy.dlq` | — | Nega toda comunicação não-HTTPS com a DLQ. |

---

## Controles de Segurança

| Controle | Implementação |
|---|---|
| Criptografia em repouso | SSE-SQS (padrão, sem custo extra) ou SSE-KMS quando `kms_key_arn` é fornecido |
| Criptografia em trânsito | Queue Policy com `aws:SecureTransport = false → Deny` em ambas as filas |
| Sem acesso público | Nenhum `Principal: "*"` permissivo — apenas a policy de deny explícito |
| Redrive restrito | `redrivePermission = byQueue` — só a fila principal pode enviar para a DLQ |
| Least privilege | Permissões de produtores/consumidores ficam em IAM roles externas, não na queue policy |

---

## Variáveis

| Variável | Tipo | Default | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Prefixo do projeto. |
| `environment` | `string` | — | `dev`, `staging` ou `prod`. |
| `aws_region` | `string` | — | Região AWS. |
| `queue_name_suffix` | `string` | — | Sufixo que identifica o propósito da fila (ex: `file-events`, `orders`). |
| `visibility_timeout_seconds` | `number` | `30` | Tempo de invisibilidade após recebimento. Deve ser ≥ ao tempo de processamento do consumidor. |
| `message_retention_seconds` | `number` | `345600` | Retenção de mensagens (4 dias default, máx 14 dias). |
| `max_message_size` | `number` | `262144` | Tamanho máximo de mensagem em bytes (256 KB). |
| `delay_seconds` | `number` | `0` | Delay de entrega de novas mensagens. |
| `receive_wait_time_seconds` | `number` | `20` | Long polling — 20s é o máximo e o recomendado. |
| `max_receive_count` | `number` | `3` | Tentativas antes de redirecionar para a DLQ. |
| `dlq_message_retention_seconds` | `number` | `1209600` | Retenção na DLQ (14 dias = máximo). |
| `kms_key_arn` | `string` | `""` | ARN de chave KMS para SSE-KMS. Vazio = SSE-SQS. |
| `kms_data_key_reuse_period_seconds` | `number` | `300` | Tempo de reuso da data key KMS (ignorado sem KMS). |
| `tags` | `map(string)` | `{}` | Tags adicionais. |

---

## Outputs

| Output | Descrição |
|---|---|
| `this_sqs_queue_id` | URL da fila (usado como ID nas chamadas SDK). |
| `this_sqs_queue_arn` | ARN da fila — use em IAM policies e event source mappings. |
| `this_sqs_queue_name` | Nome da fila. |
| `this_sqs_queue_url` | URL da fila. |
| `dlq_sqs_queue_id` | URL da DLQ. |
| `dlq_sqs_queue_arn` | ARN da DLQ. |
| `dlq_sqs_queue_name` | Nome da DLQ. |

---

## Decisões de design

| Decisão | Motivo |
|---|---|
| DLQ sempre criada | Sem DLQ, mensagens com falha ficam presas indefinidamente na fila ou são descartadas após o timeout de retenção, sem rastreabilidade. |
| Long polling padrão (20s) | Reduz chamadas `ReceiveMessage` vazias em até 95%, diminuindo custo e latência. |
| SSE-SQS como padrão | Criptografia gerenciada pela AWS, sem custo adicional. SSE-KMS disponível quando compliance exige CMK. |
| `sqs_managed_sse_enabled` e `kms_master_key_id` mutuamente exclusivos | A AWS não permite ambos simultaneamente — a lógica `local.use_kms` garante que apenas um seja definido. |
| `aws_sqs_queue_policy` separado do `aws_sqs_queue` | Evita drift silencioso — mudanças de policy não forçam recreação da fila. |
| `Version = "2012-10-17"` garantido pelo `aws_iam_policy_document` | Sem essa versão, a AWS fica em loop durante a criação da queue policy (bug documentado no provider). |
| Retenção da DLQ = 14 dias (máximo) | Garante janela máxima para investigar e reprocessar falhas antes de perder as mensagens. |

---

## Como usar o ARN da fila em outras stacks

O `this_sqs_queue_arn` é o valor tipicamente consumido por:

- **Lambda (event source mapping):** `aws_lambda_event_source_mapping.source_arn`
- **IAM policy do produtor:** `actions = ["sqs:SendMessage"]`, `resources = [<arn>]`
- **IAM policy do consumidor:** `actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]`

---

## Regra para o `visibility_timeout_seconds`

> Deve ser **maior ou igual** ao tempo máximo de processamento do consumidor.

| Consumidor | Recomendação |
|---|---|
| Lambda (timeout 60s) | `visibility_timeout_seconds >= 60` |
| Lambda (timeout 300s) | `visibility_timeout_seconds >= 300` |
| EC2 / ECS (processamento variável) | Ajustar via `ChangeMessageVisibility` durante o processamento |

---

## Comandos

```bash
# Init
terraform init

# Plan
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars

# Destroy
terraform destroy -var-file=environments/dev.tfvars
```

---

## Provider

| Provider | Versão |
|---|---|
| `hashicorp/aws` | `~> 6.50` |
