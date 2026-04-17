<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import ModalHeader from 'dashboard/components/ModalHeader.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'insert', 'update:show']);
const { t } = useI18n();
const store = useStore();

onMounted(() => {
  store.dispatch('attributes/get');
});

const standardVariables = computed(() => [
  { key: 'first_name', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.FIRST_NAME') || 'Primeiro Nome', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.FIRST_NAME') || 'Primeiro nome do contato' },
  { key: 'last_name', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.LAST_NAME') || 'Sobrenome', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.LAST_NAME') || 'Sobrenome do contato' },
  { key: 'full_name', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.FULL_NAME') || 'Nome Completo', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.FULL_NAME') || 'Nome completo do contato' },
  { key: 'email', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.EMAIL') || 'E-mail', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.EMAIL') || 'E-mail do contato' },
  { key: 'phone', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.PHONE') || 'Telefone', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.PHONE') || 'Telefone do contato' },
  { key: 'city', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.CITY') || 'Cidade', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.CITY') || 'Cidade do contato' },
  { key: 'country', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.COUNTRY') || 'País', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.COUNTRY') || 'País do contato' },
  { key: 'company_name', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.COMPANY_NAME') || 'Empresa', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.COMPANY_NAME') || 'Nome da empresa' },
  { key: 'bio', label: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.STANDARD.BIO') || 'Bio', description: t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.DESCRIPTIONS.BIO') || 'Bio/Descrição do contato' },
]);

const customAttributes = computed(() => {
  return store.getters['attributes/getContactAttributes'] || [];
});

const localShow = computed({
  get: () => props.show,
  set: (val) => emit('update:show', val)
});

const onClose = () => {
  emit('close');
  emit('update:show', false);
};

const insertVariable = (variableKey, isCustom = false) => {
  const variableString = isCustom ? `ca_${variableKey}` : variableKey;
  emit('insert', variableString);
  onClose();
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-lg">
    <ModalHeader
      :header-title="t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.MODAL_TITLE') || 'Inserir Variável'"
      :header-content="t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.MODAL_SUBTITLE') || 'Selecione uma variável para inserir no corpo da mensagem.'"
    />
    <div class="px-8 pb-8 flex flex-col gap-6 max-h-[60vh] overflow-y-auto w-[600px] max-w-full">
      
      <!-- System Variables -->
      <div>
        <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100 mb-3">
          {{ t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.SYSTEM_VARIABLES') || 'Variáveis do Sistema' }}
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <button
            v-for="v in standardVariables"
            :key="v.key"
            class="flex flex-col items-start p-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 hover:border-slate-300 dark:hover:border-slate-600 transition-colors cursor-pointer text-left"
            @click="insertVariable(v.key)"
          >
            <span class="font-medium text-sm text-slate-900 dark:text-slate-50">{{ v.label }}</span>
            <span class="text-xs text-slate-500 dark:text-slate-400 mt-1">{{ v.description }}</span>
            <span class="text-[10px] font-mono text-slate-400 dark:text-slate-500 mt-2 bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded">{{ '{' + '{' + v.key + '}' + '}' }}</span>
          </button>
        </div>
      </div>

      <!-- Custom Variables -->
      <div>
        <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100 mb-3">
          {{ t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.CUSTOM_VARIABLES') || 'Atributos Customizados' }}
        </h3>
        <div v-if="customAttributes.length === 0" class="text-sm text-slate-500 italic">
          {{ t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.NO_CUSTOM_VARIABLES') || 'Nenhum atributo customizado encontrado.' }}
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <button
            v-for="attr in customAttributes"
            :key="attr.attributeKey"
            class="flex flex-col items-start p-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 hover:border-slate-300 dark:hover:border-slate-600 transition-colors cursor-pointer text-left"
            @click="insertVariable(attr.attributeKey, true)"
          >
            <span class="font-medium text-sm text-slate-900 dark:text-slate-50">{{ attr.attributeDisplayName || attr.attributeKey }}</span>
            <span class="text-xs text-slate-500 dark:text-slate-400 mt-1">{{ attr.attributeDescription || 'Atributo customizado' }}</span>
            <span class="text-[10px] font-mono text-slate-400 dark:text-slate-500 mt-2 bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded">{{ '{' + '{ca_' + attr.attributeKey + '}' + '}' }}</span>
          </button>
        </div>
      </div>

    </div>
  </woot-modal>
</template>
