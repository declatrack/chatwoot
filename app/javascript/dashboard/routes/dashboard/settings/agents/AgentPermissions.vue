<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const isLoading = ref(true);
const isSaving = ref(false);
const agent = ref(null);

// Permissions
const canTransferTeam = ref(true);
const canTransferAgent = ref(true);
const canViewContacts = ref(true);
const canEditContacts = ref(true);
const canViewInboxTab = ref(true);
const canViewMentionsTab = ref(true);
const canViewUnattendedTab = ref(true);
const canViewChannelsTab = ref(true);
const canViewTeamsTab = ref(true);
const canViewOnlyAssigned = ref(false);
const canViewSettings = ref(false);
const canViewCaptain = ref(false);
const teamConversationVisibility = ref('team_and_unassigned');

const VISIBILITY_OPTIONS = [
  {
    value: 'team_and_unassigned',
    label: 'Time + Sem Time',
    description: 'Vê conversas dos times e as sem time atribuído. (Padrão)',
    icon: 'i-lucide-users',
  },
  {
    value: 'team_only',
    label: 'Somente do Time',
    description: 'Vê apenas conversas dos times em que participa. Sem time = oculto.',
    icon: 'i-lucide-shield',
  },
  {
    value: 'all_inbox',
    label: 'Todos os Inboxes',
    description: 'Vê todas as conversas dos Inboxes que tem acesso, independente do time.',
    icon: 'i-lucide-inbox',
  },
];

const agentId = computed(() => Number(route.params.agentId));

const pageTitle = computed(() => {
  return agent.value
    ? `Permissões — ${agent.value.name}`
    : 'Permissões do Agente';
});

const isAdmin = computed(() => agent.value?.role === 'administrator');

const loadAgent = async () => {
  isLoading.value = true;
  try {
    await store.dispatch('agents/get');
    const agents = store.getters['agents/getAgents'];
    agent.value = agents.find(a => a.id === agentId.value);
    if (agent.value) {
      const perms = agent.value.agent_permissions || {};
      canTransferTeam.value = perms.can_transfer_team ?? true;
      canTransferAgent.value = perms.can_transfer_agent ?? true;
      canViewContacts.value = perms.can_view_contacts ?? true;
      canEditContacts.value = perms.can_edit_contacts ?? true;
      canViewInboxTab.value = perms.can_view_inbox_tab ?? true;
      canViewMentionsTab.value = perms.can_view_mentions_tab ?? true;
      canViewUnattendedTab.value = perms.can_view_unattended_tab ?? true;
      canViewChannelsTab.value = perms.can_view_channels_tab ?? true;
      canViewTeamsTab.value = perms.can_view_teams_tab ?? true;
      canViewOnlyAssigned.value = perms.can_view_only_assigned ?? false;
      canViewSettings.value = perms.can_view_settings ?? false;
      canViewCaptain.value = perms.can_view_captain ?? false;
      teamConversationVisibility.value = perms.team_conversation_visibility ?? 'team_and_unassigned';
    }
  } catch (error) {
    useAlert('Erro ao carregar agente');
  } finally {
    isLoading.value = false;
  }
};

const savePermissions = async () => {
  isSaving.value = true;
  try {
    const payload = {
      id: agentId.value,
      permissions: {
        can_transfer_team: canTransferTeam.value,
        can_transfer_agent: canTransferAgent.value,
        can_view_contacts: canViewContacts.value,
        can_edit_contacts: canEditContacts.value,
        can_view_inbox_tab: canViewInboxTab.value,
        can_view_mentions_tab: canViewMentionsTab.value,
        can_view_unattended_tab: canViewUnattendedTab.value,
        can_view_channels_tab: canViewChannelsTab.value,
        can_view_teams_tab: canViewTeamsTab.value,
        can_view_only_assigned: canViewOnlyAssigned.value,
        can_view_settings: canViewSettings.value,
        can_view_captain: canViewCaptain.value,
        team_conversation_visibility: teamConversationVisibility.value,
      },
    };
    await store.dispatch('agents/update', payload);
    useAlert('Permissões salvas com sucesso!');
  } catch (error) {
    useAlert('Erro ao salvar permissões.');
  } finally {
    isSaving.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'agent_list' });
};

onMounted(loadAgent);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    loading-message="Carregando agente..."
    :no-records-found="!agent && !isLoading"
    no-records-message="Agente não encontrado"
  >
    <template #header>
      <div class="flex items-center justify-between w-full py-3">
        <div class="flex items-center gap-3">
          <Button
            ghost
            slate
            icon="i-lucide-arrow-left"
            size="sm"
            @click="goBack"
          />
          <div>
            <h2 class="text-lg font-semibold text-n-slate-12">
              {{ pageTitle }}
            </h2>
            <p class="text-sm text-n-slate-11">
              Configure o que este agente pode acessar e fazer no sistema.
            </p>
          </div>
        </div>
        <Button
          :label="isSaving ? 'Salvando...' : 'Salvar Permissões'"
          :disabled="isSaving || isAdmin"
          :is-loading="isSaving"
          size="sm"
          @click="savePermissions"
        />
      </div>
    </template>

    <template #body>
      <div v-if="agent" class="max-w-3xl space-y-6">
        <!-- Admin Notice -->
        <div
          v-if="isAdmin"
          class="flex items-center gap-2 px-4 py-3 text-sm rounded-lg bg-n-amber-2 text-n-amber-11 border border-n-amber-6"
        >
          <span class="i-lucide-shield-check text-base" />
          <span>
            Administradores possuem <strong>todas as permissões</strong> automaticamente. As configurações abaixo não se aplicam a eles.
          </span>
        </div>

        <!-- Conversas -->
        <div class="rounded-lg border border-n-weak bg-white dark:bg-n-solid-2 overflow-hidden">
          <div class="px-4 py-3 border-b border-n-weak bg-n-slate-2">
            <h3 class="text-sm font-semibold text-n-slate-12 flex items-center gap-2">
              <span class="i-lucide-message-square text-base" />
              Conversas
            </h3>
          </div>
          <div class="px-4 py-4 space-y-4">
            <SettingsToggleSection
              v-model="canViewInboxTab"
              compact
              header="Aba 'Caixa de Entrada'"
              description="Permite ao agente visualizar a aba 'Caixa de Entrada' no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewMentionsTab"
              compact
              header="Aba 'Menções'"
              description="Permite ao agente visualizar a aba 'Menções' no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewUnattendedTab"
              compact
              header="Aba 'Não Atendidas'"
              description="Permite ao agente visualizar a aba 'Não Atendidas' no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewChannelsTab"
              compact
              header="Aba 'Canais'"
              description="Permite ao agente visualizar as conversas separadas por 'Caixas de Entrada/Canais' no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewTeamsTab"
              compact
              header="Aba 'Times'"
              description="Permite ao agente visualizar as conversas separadas por 'Times' no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewOnlyAssigned"
              compact
              header="Ver apenas conversas atribuídas"
              description="Quando ativado, o agente verá apenas as conversas atribuídas a ele. Limita automaticamente todas as abas onde ele possa ver outras conversas."
            />

            <!-- Team Conversation Visibility -->
            <div class="pt-2">
              <div class="mb-3">
                <p class="text-sm font-medium text-n-slate-12">Visibilidade de Conversas por Time</p>
                <p class="text-xs text-n-slate-11 mt-0.5">Define quais conversas este agente enxerga com base nos times em que participa.</p>
              </div>
              <div class="grid grid-cols-1 gap-2 sm:grid-cols-3">
                <button
                  v-for="option in VISIBILITY_OPTIONS"
                  :key="option.value"
                  type="button"
                  class="flex flex-col gap-1.5 rounded-lg border px-3 py-3 text-left transition-all focus:outline-none"
                  :class="teamConversationVisibility === option.value
                    ? 'border-n-blue-8 bg-n-blue-2 ring-1 ring-n-blue-8'
                    : 'border-n-weak bg-white dark:bg-n-solid-2 hover:border-n-slate-7 hover:bg-n-slate-2'"
                  :disabled="isAdmin"
                  @click="teamConversationVisibility = option.value"
                >
                  <div class="flex items-center gap-2">
                    <span
                      class="text-sm"
                      :class="[option.icon, teamConversationVisibility === option.value ? 'text-n-blue-9' : 'text-n-slate-10']"
                    />
                    <span
                      class="text-xs font-semibold"
                      :class="teamConversationVisibility === option.value ? 'text-n-blue-11' : 'text-n-slate-12'"
                    >{{ option.label }}</span>
                  </div>
                  <p class="text-xs leading-snug" :class="teamConversationVisibility === option.value ? 'text-n-blue-10' : 'text-n-slate-10'">
                    {{ option.description }}
                  </p>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Transferências -->
        <div class="rounded-lg border border-n-weak bg-white dark:bg-n-solid-2 overflow-hidden">
          <div class="px-4 py-3 border-b border-n-weak bg-n-slate-2">
            <h3 class="text-sm font-semibold text-n-slate-12 flex items-center gap-2">
              <span class="i-lucide-arrow-right-left text-base" />
              Transferências
            </h3>
          </div>
          <div class="px-4 py-4 space-y-4">
            <SettingsToggleSection
              v-model="canTransferTeam"
              compact
              header="Transferir para outro time"
              description="Permite ao agente transferir conversas para times diferentes do seu. Se desativado, o seletor de time ficará oculto."
            />
            <SettingsToggleSection
              v-model="canTransferAgent"
              compact
              header="Reatribuir para outro agente"
              description="Permite ao agente atribuir conversas para outros agentes. Se desativado, o seletor de agente ficará oculto."
            />
          </div>
        </div>

        <!-- Contatos -->
        <div class="rounded-lg border border-n-weak bg-white dark:bg-n-solid-2 overflow-hidden">
          <div class="px-4 py-3 border-b border-n-weak bg-n-slate-2">
            <h3 class="text-sm font-semibold text-n-slate-12 flex items-center gap-2">
              <span class="i-lucide-contact text-base" />
              Contatos
            </h3>
          </div>
          <div class="px-4 py-4 space-y-4">
            <SettingsToggleSection
              v-model="canViewContacts"
              compact
              header="Ver contatos"
              description="Permite ao agente acessar a seção de Contatos no menu lateral. Se desativado, o menu 'Contatos' ficará oculto."
            />
            <SettingsToggleSection
              v-model="canEditContacts"
              compact
              header="Editar contatos"
              description="Permite ao agente editar informações dos contatos (nome, email, telefone, atributos customizados)."
            />
          </div>
        </div>

        <!-- Menus Extras -->
        <div class="rounded-lg border border-n-weak bg-white dark:bg-n-solid-2 overflow-hidden">
          <div class="px-4 py-3 border-b border-n-weak bg-n-slate-2">
            <h3 class="text-sm font-semibold text-n-slate-12 flex items-center gap-2">
              <span class="i-lucide-menu text-base" />
              Acesso a Menus
            </h3>
          </div>
          <div class="px-4 py-4 space-y-4">
            <SettingsToggleSection
              v-model="canViewCaptain"
              compact
              header="Capitão"
              description="Permite ao agente acessar e usar as funcionalidades do Capitão no menu lateral."
            />
            <SettingsToggleSection
              v-model="canViewSettings"
              compact
              header="Configurações"
              description="Permite ao agente visualizar a seção de Configurações no menu lateral."
            />
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
