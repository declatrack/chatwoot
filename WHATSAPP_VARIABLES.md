# Guia de Variáveis para Templates do WhatsApp (Chatwoot Customizado)

Este documento explica como utilizar a nova lógica de auto-preenchimento de variáveis nos seus modelos (templates) da Meta dentro do seu ambiente Chatwoot.

## 1. Variáveis Padrão Disponíveis

Ao criar um template na Meta, você pode usar os seguintes nomes de variáveis (dentro de `{{ }}`) para que o sistema as preencha automaticamente com os dados do contato:

| Variável | Descrição | Origem no Chatwoot |
| :--- | :--- | :--- |
| `{{first_name}}` | Primeiro nome do contato | Extraído do campo Nome |
| `{{last_name}}` | Sobrenome do contato | Extraído do campo Nome |
| `{{full_name}}`| Nome completo do contato | Campo Nome |
| `{{email}}` | E-mail do contato | Campo E-mail |
| `{{phone}}` | Telefone do contato | Campo Telefone |
| `{{city}}`  | Cidade do contato | Atributos Adicionais / Customizados |
| `{{country}}`| País do contato | Atributos Adicionais / Customizados |
| `{{company_name}}`  | Nome da empresa | Atributos Adicionais / Customizados |
| `{{bio}}` | Bio/Descrição do contato | Campo Descrição ou Atributos |

---

## 2. Atributos Customizados (`ca_`)

Para utilizar qualquer outro **Atributo Customizado** que você criou no Chatwoot, utilize o prefixo `ca_` seguido do nome (slug) do atributo.

**Exemplo:**
Se você tem um atributo customizado chamado `setor`, a variável no template deve ser:
`{{ca_setor}}`

**Como funciona:**
1. O sistema identifica o prefixo `ca_`.
2. Remove o `ca_` e busca exatamente pelo nome restante nos Atributos Customizados do contato.
3. Se o contato tiver um valor salvo para `setor`, ele será preenchido. Caso contrário, o campo aparecerá vazio para preenchimento manual no modal.

---

## 3. Formatação Automática de Datas

O sistema possui uma inteligência para detectar datas. Se o valor recuperado do contato estiver no formato ISO (ex: `2026-02-26T03:00:00Z`), ele será automaticamente convertido para o padrão brasileiro:

**`dd/mm/aaaa`**

Isso se aplica tanto a atributos padrão quanto a atributos customizados (ex: `{{ca_data_vencimento}}`).

---

## 4. Exemplo Completo de Template

**Texto no Gerenciador da Meta:**
> Olá {{first_name}}, notei que você trabalha na empresa {{company_name}} e mora em {{city}}. Sua fatura vence no dia {{ca_vencimento}}.

**Resultado no Chatwoot (Auto-preenchido):**
> Olá Armando, notei que você trabalha na empresa Minha Loja e mora em Imperatriz. Sua fatura vence no dia 26/02/2026.

---

## Dicas Importantes
- **Prioridade:** Para campos como `city` ou `country`, o sistema busca primeiro nos "Atributos Adicionais" e depois nos "Atributos Customizados".
- **Sensibilidade:** O sistema trata os nomes das variáveis como *case-insensitive* (não diferencia maiúsculas de minúsculas) para facilitar o mapeamento.
- **Edição:** Mesmo com o auto-preenchimento, você **ainda pode editar** o valor no modal antes de clicar em "Enviar Mensagem" caso precise fazer algum ajuste pontual.
