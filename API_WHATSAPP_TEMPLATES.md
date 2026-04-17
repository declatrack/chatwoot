# Guia de Uso: API de Templates WhatsApp (Smart Auto-fill)

Este documento descreve como utilizar a API do Chatwoot customizada para enviar templates do WhatsApp de forma inteligente, aproveitando o motor de **Auto-preenchimento (Smart Auto-fill)** e a unificação da visualização no Chat.

---

## 🚀 Como Funciona

O motor de inteligência reside no backend e é acionado sempre que uma mensagem do tipo `template` é enviada via API. Ele analisa o texto do template cadastrado na Meta e tenta resolver as variáveis `{{...}}` de forma automática.

### Benefícios:
- **API Limpa**: Você não precisa enviar dados que o Chatwoot já possui.
- **Histórico Perfeito**: O texto renderizado aparece no chat do Chatwoot exatamente como chegou no WhatsApp.
- **Máscara de Data**: Conversão automática para o padrão brasileiro (`DD/MM/AAAA`).
- **Resiliência**: Se um dado estiver faltando no contato, o sistema insere um `-` para evitar que a Meta rejeite a mensagem.

---

## 🛠️ Detalhes da Requisição

**Endpoint:** `POST` `/api/v1/accounts/{account_id}/conversations/{conversation_id}/messages`  
**Headers:**
- `api_access_token`: Seu Token de Acesso (agente ou admin)
- `Content-Type`: `application/json`

---

## 📝 Exemplos de Payload

### 1. Auto-preenchimento Total (Mínimo de Esforço)
Use este modo quando você quer que o Chatwoot preencha tudo com base nos dados do contato.

**Template Exemplo:**  
`"Olá, {{full_name}}. Sua fatura de {{ca_vencimento}} está disponível."`

**Payload:**
```json
{
  "message_type": "template",
  "content_type": "text",
  "template_params": {
    "name": "nome_do_template",
    "language": "pt_BR",
    "processed_params": {
      "body": {}
    }
  }
}
```
**Resultado:** O sistema detecta `full_name` e `ca_vencimento` e preenche automaticamente.

---

### 2. Substituição Manual (Prioridade da API)
Se você enviar um valor manual no JSON, o sistema **não irá sobrescrevê-lo**. Isso é útil para códigos de rastreamento ou protocolos gerados fora do CRM.

**Payload:**
```json
{
  "message_type": "template",
  "content_type": "text",
  "template_params": {
    "name": "nome_do_template",
    "language": "pt_BR",
    "processed_params": {
      "body": {
        "protocolo": "ABC-12345"
      }
    }
  }
}
```
**Resultado:** `protocolo` será enviado como `ABC-12345`. Variáveis não informadas (como `full_name`) continuarão sendo auto-preenchidas.

---

## 🔍 Variáveis Suportadas

### Variáveis do Sistema (Nativas)
| Variável | Origem |
| :--- | :--- |
| `{{first_name}}` | Primeiro nome do contato |
| `{{last_name}}` | Sobrenome do contato |
| `{{full_name}}` | Nome completo |
| `{{email}}` | E-mail principal |
| `{{phone}}` | Número de telefone |
| `{{city}}` | Cidade (Atributos Adicionais) |
| `{{country}}` | País (Código ou Nome) |
| `{{company_name}}` | Nome da empresa vinculada |

### Atributos Customizados (`ca_`)
Para usar qualquer atributo personalizado criado no Chatwoot, utilize o prefixo `ca_` seguido pela chave do atributo.
- Ex: `{{ca_cpf}}`, `{{ca_status_financeiro}}`, `{{ca_id_veiculo}}`.

---

## 📅 Formatação de Datas
O sistema possui inteligência para detectar datas no formato ISO (`YYYY-MM-DD`) vindas do banco de dados e convertê-las para o padrão brasileiro:
- **Entrada (BD):** `2026-04-17`
- **Saída (WhatsApp/Chat):** `17/04/2026`

---

## 🖥️ Visualização no Chatwoot

Diferente de uma API comum que deixaria a mensagem em branco no histórico, esta implementação:
1.  Busca o texto do template no banco de dados.
2.  Substitui as variáveis pelos valores reais (respeitando sua prioridade).
3.  Salva o resultado no campo `content`.

Isso garante que ao abrir a conversa `https://.../app/accounts/1/conversations/9`, você veja exatamente o que o cliente recebeu.

---

> [!TIP]
> **Dica de Debug**: Se as mensagens não estiverem chegando, verifique se o nome do template e o idioma no JSON são exatamente iguais aos aprovados no Gerenciador de WhatsApp da Meta.
