#!/bin/bash
# =============================================================
# Teste: Envio e Consulta de Mensagem + Delivery Logs
# =============================================================
# Ajuste as variáveis abaixo antes de rodar:
#   chmod +x tests_scripts/test_message_delivery.sh
#   ./tests_scripts/test_message_delivery.sh
# =============================================================

# -- Variáveis de configuração --------------------------------
BASE_URL="https://test-local.deskcrm.com.br"
API_TOKEN="WhUD6GYtLU9zqHz2XPKckZ8C"
ACCOUNT_ID="1"
CONVERSATION_ID="1"          # ID (display_id) da conversa alvo
MESSAGE_CONTENT="Mensagem de teste via script - $(date '+%Y-%m-%d %H:%M:%S')"
# -------------------------------------------------------------

MESSAGES_URL="${BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${CONVERSATION_ID}/messages"

echo "=============================================="
echo "  CHATWOOT — Teste de Envio + Delivery Logs"
echo "=============================================="
echo ""

# ── PASSO 1: Criar mensagem ────────────────────────────────
echo "→ [1/2] Enviando mensagem para a conversa #${CONVERSATION_ID}..."
echo "   Conteúdo: \"${MESSAGE_CONTENT}\""
echo ""

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${MESSAGES_URL}" \
  -H "api_access_token: ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"${MESSAGE_CONTENT}\", \"message_type\": \"outgoing\"}")

HTTP_STATUS=$(echo "$CREATE_RESPONSE" | tail -1)
BODY=$(echo "$CREATE_RESPONSE" | head -n -1)

if [ "$HTTP_STATUS" != "200" ] && [ "$HTTP_STATUS" != "201" ]; then
  echo "✗ Erro ao criar mensagem (HTTP ${HTTP_STATUS}):"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

MESSAGE_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

if [ -z "$MESSAGE_ID" ]; then
  echo "✗ Não foi possível extrair o ID da mensagem. Resposta recebida:"
  echo "$BODY"
  exit 1
fi

echo "✓ Mensagem criada com sucesso!"
echo "   ID da mensagem : ${MESSAGE_ID}"
echo "   Status inicial : $(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status','?'))" 2>/dev/null)"
echo ""

# ── PASSO 2: Consultar mensagem com delivery logs ──────────
echo "→ [2/2] Consultando mensagem #${MESSAGE_ID} com delivery logs..."
echo ""

# Aguarda 1s para o SendReplyJob ter chance de processar
sleep 1

SHOW_RESPONSE=$(curl -s -w "\n%{http_code}" \
  "${MESSAGES_URL}/${MESSAGE_ID}" \
  -H "api_access_token: ${API_TOKEN}")

HTTP_STATUS=$(echo "$SHOW_RESPONSE" | tail -1)
SHOW_BODY=$(echo "$SHOW_RESPONSE" | head -n -1)

if [ "$HTTP_STATUS" != "200" ]; then
  echo "✗ Erro ao consultar mensagem (HTTP ${HTTP_STATUS}):"
  echo "$SHOW_BODY" | python3 -m json.tool 2>/dev/null || echo "$SHOW_BODY"
  exit 1
fi

echo "✓ Consulta realizada com sucesso (HTTP ${HTTP_STATUS})"
echo ""
echo "──────────────────────────────────────────────"
echo "  Dados da Mensagem"
echo "──────────────────────────────────────────────"
echo "$SHOW_BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"  ID            : {data.get('id')}\")
print(f\"  Conteúdo      : {data.get('content')}\")
print(f\"  Status        : {data.get('status')}\")
print(f\"  Tipo          : {data.get('message_type')}\")
print(f\"  Canal         : {data.get('channel_type')}\")
print(f\"  Source ID     : {data.get('source_id')}\")
print()
logs = data.get('delivery_logs', [])
print(f\"  Delivery Logs : {len(logs)} registro(s)\")
print()
for i, log in enumerate(logs, 1):
    status_icon = '✓' if log.get('status') == 'success' else ('✗' if log.get('status') == 'failed' else '○')
    print(f\"  [{status_icon}] Log #{i}\")
    print(f\"      Status           : {log.get('status')}\")
    print(f\"      Canal            : {log.get('channel_type')}\")
    print(f\"      External Msg ID  : {log.get('external_message_id') or 'N/A'}\")
    print(f\"      Erro             : {log.get('error_message') or 'Nenhum'}\")
    print(f\"      Tentativa em     : {log.get('attempted_at')}\")
    print()
" 2>/dev/null || echo "$SHOW_BODY" | python3 -m json.tool

echo "──────────────────────────────────────────────"
echo "  Teste concluído."
echo "=============================================="
