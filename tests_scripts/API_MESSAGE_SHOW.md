# GET Message — Documentação da Rota de Consulta

Rota que retorna os detalhes de uma mensagem específica junto com o histórico completo de tentativas de entrega ao canal externo (WhatsApp, Telegram, Instagram, etc.).

---

## Endpoint

```
GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages/{message_id}
```

## Autenticação

| Header | Valor |
|---|---|
| `api_access_token` | Token de API do agente ou administrador |

---

## Parâmetros de URL

| Parâmetro | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `account_id` | integer | ✅ | ID da conta no Chatwoot |
| `conversation_id` | integer | ✅ | `display_id` da conversa (número visível na URL do dashboard) |
| `message_id` | integer | ✅ | ID interno da mensagem retornado no momento da criação |

---

## Exemplo de Requisição

```bash
curl -s \
  "http://localhost:3000/api/v1/accounts/1/conversations/1/messages/2" \
  -H "api_access_token: SEU_TOKEN"
```

---

## Resposta de Sucesso — `200 OK`

```json
{
  "id": 2,
  "content": "Mensagem de teste via script - 2026-03-20 20:00:22",
  "inbox_id": 1,
  "conversation_id": 1,
  "message_type": "outgoing",
  "content_type": "text",
  "status": "sent",
  "private": false,
  "source_id": "wamid.HBgMNTUzNDk4MDkyNjQwFQIAERgSOTA0RENBM0NGREJENTYwRDRDAA==",
  "channel_type": "Channel::Whatsapp",
  "created_at": 1742515222,
  "content_attributes": {},
  "additional_attributes": {},
  "sender": {
    "id": 1,
    "name": "Agente Teste",
    "type": "user"
  },
  "attachments": [],
  "delivery_logs": [
    {
      "id": 2,
      "status": "success",
      "channel_type": "Channel::Whatsapp",
      "external_message_id": "wamid.HBgMNTUzNDk4MDkyNjQwFQIAERgSOTA0RENBM0NGREJENTYwRDRDAA==",
      "error_message": null,
      "response_body": {},
      "attempted_at": "2026-03-20T23:00:23Z",
      "created_at": "2026-03-20T23:00:23Z"
    },
    {
      "id": 1,
      "status": "pending",
      "channel_type": "Channel::Whatsapp",
      "external_message_id": null,
      "error_message": null,
      "response_body": {},
      "attempted_at": "2026-03-20T23:00:22Z",
      "created_at": "2026-03-20T23:00:22Z"
    }
  ]
}
```

---

## Descrição dos Campos

### Campos da Mensagem

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | ID interno da mensagem no Chatwoot |
| `content` | string | Texto da mensagem |
| `inbox_id` | integer | ID do inbox (canal) pelo qual foi enviada |
| `conversation_id` | integer | ID da conversa (display_id) |
| `message_type` | string | `outgoing` (agente→contato) / `incoming` (contato→agente) / `activity` / `template` |
| `content_type` | string | `text`, `image`, `cards`, `form`, `input_csat`, etc. |
| `status` | string | Status da mensagem no Chatwoot — ver tabela abaixo |
| `private` | boolean | `true` = nota privada entre agentes (nunca enviada ao canal) |
| `source_id` | string | ID externo retornado pelo canal (ex: `wamid.xxx` do WhatsApp) |
| `channel_type` | string | Classe do canal: `Channel::Whatsapp`, `Channel::Telegram`, `Channel::Instagram`, etc. |
| `created_at` | integer | Timestamp Unix de criação |
| `content_attributes` | object | Metadados extras: `in_reply_to`, `external_error`, traduções, dados de email, etc. |
| `additional_attributes` | object | Atributos adicionais: `campaign_id`, `template_params`, etc. |
| `sender` | object | Dados de quem enviou (agente, bot ou contato) |
| `attachments` | array | Lista de anexos (`image`, `audio`, `file`, `video`, `location`) |

### Status da Mensagem (`status`)

| Valor | Significado |
|---|---|
| `sent` | Mensagem criada e enviada ao canal. **Estado padrão.** Aguarda confirmação de entrega |
| `delivered` | Canal confirmou que chegou ao dispositivo do contato (via webhook) |
| `read` | Contato leu a mensagem (via webhook de leitura) |
| `failed` | Falha na entrega ao canal externo. Ver `content_attributes.external_error` para o detalhe do erro |

---

### Campos de `delivery_logs[]`

Array ordenado do mais recente para o mais antigo. Registra **cada tentativa de entrega** ao canal externo.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | ID do registro de log |
| `status` | string | `pending` / `success` / `failed` — ver tabela abaixo |
| `channel_type` | string | Canal pelo qual a entrega foi tentada |
| `external_message_id` | string \| null | ID retornado pelo canal ao aceitar a mensagem (ex: `wamid.xxx`). `null` se ainda pendente ou se houve falha |
| `error_message` | string \| null | Mensagem de erro do canal em caso de `failed`. `null` em caso de sucesso |
| `response_body` | object | Corpo bruto da resposta ou contexto adicional do canal |
| `attempted_at` | string (ISO 8601) | Data/hora exata da tentativa de entrega |
| `created_at` | string (ISO 8601) | Data/hora de criação do registro de log |

### Status do Delivery Log

| Valor | Quando é criado | Significado |
|---|---|---|
| `pending` | Imediatamente ao salvar a mensagem | Mensagem salva no DB, entrega ao canal em fila |
| `success` | Após o job de envio concluir com sucesso | Canal aceitou e confirmou a mensagem |
| `failed` | Após o job de envio lançar exceção | Canal rejeitou ou a conexão falhou |

---

## Ciclo de Vida de uma Mensagem

```
POST /messages   →  Mensagem salva no DB (status: sent)
                         │
                         └─→ delivery_log #1 criado: pending
                                   │
                                   └─→ SendReplyJob executa
                                             │
                               ┌─────────────┴─────────────┐
                          Sucesso                         Falha
                               │                             │
                    delivery_log #2: success      delivery_log #2: failed
                    external_message_id: wamid…   error_message: "..."
```

---

## Erros

| HTTP | Situação |
|---|---|
| `401 Unauthorized` | Token inválido ou ausente |
| `403 Forbidden` | Agente não tem acesso à conversa |
| `404 Not Found` | Mensagem ou conversa não encontrada |

---

## Script de Teste

Veja o script pronto em [`tests_scripts/test_message_delivery.sh`](./tests_scripts/test_message_delivery.sh).
Configure as variáveis no topo e execute:

```bash
chmod +x tests_scripts/test_message_delivery.sh
./tests_scripts/test_message_delivery.sh
```
