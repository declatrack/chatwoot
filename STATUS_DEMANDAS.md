# Status e Especificação Detalhada das Demandas

Com base em tudo o que codificamos até agora e nos requisitos que você anexou, preparei o diagnóstico e panorama geral. A boa notícia é que **muitas coisas já estão completamente resolvidas nas nossas sprints!**

Por outro lado, algumas lógicas organizacionais e de privacidade que você descreveu (ex: agentes não poderem digitar ou resolver conversas as quais não estão atribuídos) demandarão customizações profundas no Chatwoot (tanto no Backend-Ruby, quanto no Frontend-Vue) pois **estas funções não nasceram assim nativamente.**

---

## ✅ O QUE JÁ FOI FEITO E CONCLUÍDO (Pronto para Uso)

As funcionalidades de Templates e validação de WhatsApp Business já estão adaptadas à Meta (Facebook) e finalizadas:

1. **Demanda 5 - Busca em templates (Corpo ou Título):**
   - **FEITO:** Na tela de selecionar templates, incluímos a barra de busca "Pesquisar..." que traz matches tanto pelo Nome do template, quanto por qualquer palavra dentro do Corpo dele.

2. **Auto-preenchimento de Variáveis em Templates (Auto-fill):**
   - **FEITO:** Funcionalidade que mapeia automaticamente `first_name`, `email`, ou até campos costumizados como `ca_data_de_vencimento` puxados do contato no momento que o atendente seleciona enviar um template do WhatsApp. E incluído máscara brasileira de datas (`DD/MM/AAAA`).
3. **Validações e Melhorias Meta API / WhatsApp:**
   - **FEITO:** Travas para que nomes de variáveis não ultrapassem **20 caracteres** e limitação para apenas **uma (1) variável no Cabeçalho**, além de aceitar essas variáveis de fato e enviar corretamente no JSON do request da API.
   - **FEITO:** Guias aba-listas (Aprovados, Pendentes, Rejeitados, Todos) no envio do chat para templates de WhatsApp com configuração para "Todos" por default.

4. **Níveis de Permissão para Criação de Template:**
   - **FEITO:** O Botão `[+] Criar Template` e a Rota de API do backend agora aceitam apenas Administradores ou Super-admins.

5. **Demanda 6 - Assinatura do Agente no WhatsApp (Nome do Agente nas Mensagens):**
   - **FEITO:** Implementamos uma nova configuração na aba **Colaboradores** das Caixas de Entrada do tipo WhatsApp Cloud (Meta oficial). Ao ativar o toggle **"Assinatura automática nas mensagens"**, toda mensagem enviada pelo agente via chat ou API terá automaticamente o nome de exibição do agente em **negrito** antes do texto, no formato: `*NomeDoAgente* diz:` seguido da mensagem.
   - **Arquivos modificados:** Migration de banco (`enable_auto_signature`), `InboxesController`, `WhatsappCloudService`, `CollaboratorsPage.vue`, `_inbox.json.jbuilder`.

6. **Demanda de Colaborador — Visualizar sem Interagir (Agente Observador):**
   - **FEITO:** Implementação completa do sistema de permissões de interação baseado na atribuição (`assignee_id`) da conversa. Agentes não-administradores só podem interagir (responder, resolver, alterar status) com conversas que estejam **atribuídas a eles mesmos**. A funcionalidade cobre 6 camadas de proteção:

   **A) Composable de Permissão (`useConversationPermission.js` — NOVO):**
   - Criado um composable Vue reutilizável que expõe `canInteract`, calculado pela regra: `canInteract = isAdmin || (assignee_id === currentUser.id)`.
   - Usado por todos os componentes do frontend que precisam verificar se o agente pode interagir.

   **B) Ocultação do Editor de Resposta (`MessagesView.vue`):**
   - O `ReplyBox` (caixa de texto para responder) é **escondido** quando `canInteract = false`.
   - No lugar, aparece um banner com ícone de cadeado 🔒 e a mensagem: _"Você precisa assumir esta conversa para poder responder"_, acompanhado de um **botão "Assumir Conversa"** que permite ao agente se auto-atribuir com um clique.
   - Ao clicar em "Assumir Conversa", o agente se torna o `assignee` e o ReplyBox desbloqueia **instantaneamente**.

   **C) Ocultação do Botão Resolver (`MoreActions.vue`):**
   - O botão `ResolveAction` (Resolver/Reabrir) no cabeçalho da conversa fica **escondido** quando o agente não é o assignee.

   **D) Bloqueio de Status no Menu de Contexto (`contextMenu/Index.vue`):**
   - As opções de mudar status (Resolver, Reabrir, Pendente, Adiar) no clique direito sobre a conversa na lista lateral ficam **bloqueadas** quando o agente não é o assignee nem admin.
   - A prop `assigneeId` é passada do `ConversationCard.vue` para o menu de contexto.

   **E) Preservação do Status "Não Lida":**
   - **Frontend:** O método `makeMessagesRead()` em `MessagesView.vue` só executa quando `canInteract = true`. Agentes observadores **não** marcam a conversa como lida ao visualizá-la.
   - **Backend:** O endpoint `update_last_seen` em `conversations_controller.rb` recebe um `before_action :ensure_assignee_or_admin`, retornando `403 Forbidden` se o agente não é o assignee nem admin.

   **F) Proteção de API no Backend (Rails):**
   - **`messages_controller.rb`:** Adicionado `before_action :ensure_assignee_or_admin` no `create`. Agentes não-atribuídos recebem `403` ao tentar enviar mensagens via API.
   - **`conversations_controller.rb`:** Adicionado `before_action :ensure_assignee_or_admin` no `toggle_status` e no `update_last_seen`. Impede mudanças de status e marcação como lida via API.
   - O método `ensure_assignee_or_admin` permite acesso para: Admins, bots/API, e o agente atribuído à conversa.

   **G) Visibilidade de Conversas por Times (`PermissionFilterService`):**
   - Modificado o serviço `Conversations::PermissionFilterService` no backend para filtrar conversas com base na membresia de times do agente.
   - **Regra:** Conversas **sem time atribuído** (`team_id = NULL`) → visíveis para **todos** os agentes. Conversas **com time** → visíveis **apenas** para membros daquele time. **Admins** veem **tudo** sem restrição.
   - Agentes que não pertencem a nenhum time só veem conversas sem time atribuído.

   **H) Alerta de Transferência de Time (`ConversationAction.vue`):**
   - Quando um agente (não admin) tenta transferir uma conversa para um time do qual **não é membro**, aparece um alerta de confirmação: _"Se você transferir esta conversa para o time 'X', você não terá mais acesso a ela. Tem certeza que deseja transferir?"_
   - Se confirmar, transfere normalmente. Se cancelar, a ação é abortada.
   - Utiliza o getter `getMyTeams` para verificar a membresia.

   **Arquivos modificados/criados:**
   - `app/javascript/dashboard/composables/useConversationPermission.js` **(NOVO)**
   - `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue`
   - `app/javascript/dashboard/components/widgets/conversation/MoreActions.vue`
   - `app/javascript/dashboard/components/widgets/conversation/contextMenu/Index.vue`
   - `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`
   - `app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue`
   - `app/controllers/api/v1/accounts/conversations/messages_controller.rb`
   - `app/controllers/api/v1/accounts/conversations_controller.rb`
   - `app/services/conversations/permission_filter_service.rb`

     **7. Demanda 2 - Ocultar "Caixa Geral de Conversas" / Menus Laterais (CONCLUÍDO)**

   - **O que foi feito:** Toda a barra lateral agora recebe injeção dinâmica de permissões através do `AgentPermissions.vue`.
   - Foi adicionado um painel administrativo completo em **Configurações > Agentes > Editar Permissões** onde o Admin pode desligar as abas de forma independente.
   - A aba _Todas as Conversas_ foi fixada para estar sempre disponível, porém a _busca global_ foi blindada: usuários com permissão "Ver apenas conversas atribuídas" agora não conseguem contornar o acesso usando a pesquisa.
   - A restrição é testada no Frontend (`Sidebar.vue`) e na Query de Banco de Dados (`PermissionFilterService`).

7. **Demanda 3 - Envio de Template de WhatsApp em Automação com Variáveis Dinâmicas:**
   - **FEITO:** Refatoração completa da ação "Enviar Template WhatsApp Cloud" dentro das Regras de Automação.
   - **Interface Profissional:** Substituímos o seletor antigo por um menu de seleção (`select`) padrão elegante e adicionamos um preview dinâmico do conteúdo do template aprovado.
   - **Auto-preenchimento Inteligente (Smart Auto-fill):** Implementamos um interruptor (Switch) específico para variáveis de sistema (Nome, E-mail, Telefone, Cidade, etc) e atributos customizados (`ca_`).
   - **Trava de Segurança:** Quando o auto-preenchimento está ativo, o campo de entrada manual é **bloqueado (readonly)** e exibe um placeholder informativo, garantindo precisão e evitando erros humanos.
   - **Resolução de Variáveis no Backend:** Criamos um processador robusto no Rails que resolve as variáveis em tempo de execução:
     - Divide o Nome do Contato automaticamente em `{{first_name}}` e `{{last_name}}`.
     - Suporta atributos customizados e variáveis de sistema dinâmicas.
     - **Resiliência:** Se um contato não possuir um dado (ex: Empresa), o sistema injeta automaticamente um hífen `"-"` para prevenir rejeições da Meta API.
   - **Histórico de Chat Transparente:** Agora o chat registra o conteúdo literal enviado, substituindo o log genérico por uma visualização real da mensagem enviada ao cliente.
   - **Arquivos modificados:** `AutomationActionWhatsAppTemplateInput.vue`, `actionQueryGenerator.js`, `automationHelper.js`, `ActionService.rb`.

---

## 🛡️ Permissões de Agentes (Configure o que este agente pode acessar e fazer no sistema)

### Conversas

- **Aba 'Caixa de Entrada'**: Permite ao agente visualizar a aba 'Caixa de Entrada' no menu lateral.
- **Aba 'Menções'**: Permite ao agente visualizar a aba 'Menções' no menu lateral.
- **Aba 'Não Atendidas'**: Permite ao agente visualizar a aba 'Não Atendidas' no menu lateral.
- **Aba 'Canais'**: Permite ao agente visualizar as conversas separadas por 'Caixas de Entrada/Canais' no menu lateral.
- **Aba 'Times'**: Permite ao agente visualizar as conversas separadas por 'Times' no menu lateral.
- **Ver apenas conversas atribuídas**: Quando ativado, o agente verá apenas as conversas atribuídas a ele. Limita automaticamente todas as abas onde ele possa ver outras conversas.

### Transferências

- **Transferir para outro time**: Permite ao agente transferir conversas para times diferentes do seu. Se desativado, o seletor de time ficará oculto.
- **Reatribuir para outro agente**: Permite ao agente atribuir conversas para outros agentes. Se desativado, o seletor de agente ficará oculto.

### Contatos

- **Ver contatos**: Permite ao agente acessar a seção de Contatos no menu lateral. Se desativado, o menu 'Contatos' ficará oculto.
- **Editar contatos**: Permite ao agente editar informações dos contatos (nome, email, telefone, atributos customizados).

### Acesso a Menus

- **Capitão**: Permite ao agente acessar e usar as funcionalidades do Capitão no menu lateral.
- **Configurações**: Permite ao agente visualizar a seção de Configurações no menu lateral.

---

## 🟡 O QUE ESTÁ FALTANDO E PRECISA SER DESENVOLVIDO (Futuras Sprints)

### 1. Próximas Demandas...

- (A definir conforme suas prioridades de CRM).

---

Para continuarmos mantendo o projeto na estabilidade que atingimos, eu recomendo atacarmos **uma Demanda por vez**.
