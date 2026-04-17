<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  modelValue: { type: Object, default: () => ({}) },
  automation: { type: Object, required: true },
});

const emit = defineEmits(['update:modelValue']);
const { t } = useI18n();

const store = useStore();
const getters = useStoreGetters();

const automationConditions = computed(() => props.automation.conditions || []);
const inboxes = computed(() => getters['inboxes/getInboxes'].value);
const customAttributes = computed(() => getters['attributes/getContactAttributes'].value || []);

const selectedInboxCondition = computed(() => {
  return automationConditions.value.find(c => c.attribute_key === 'inbox_id');
});

const isInboxSelected = computed(() => {
  return !!selectedInboxCondition.value?.values?.[0] || !!selectedInboxCondition.value?.values;
});

const selectedInbox = computed(() => {
  if (!isInboxSelected.value) return null;
  const idValue = selectedInboxCondition.value.values;
  let idToFind = Array.isArray(idValue) ? idValue[0] : idValue;
  if (idToFind && typeof idToFind === 'object') {
    idToFind = idToFind.id;
  }
  return inboxes.value.find(i => i.id == idToFind);
});

const parsedModel = computed({
  get() {
    if (Array.isArray(props.modelValue)) {
      return props.modelValue[0] || {};
    }
    return props.modelValue || {};
  },
  set(value) {
    emit('update:modelValue', [value]);
  }
});

const isWhatsAppCloud = computed(() => {
  const channelType = selectedInbox.value?.channel_type || selectedInbox.value?.channelType;
  return channelType === 'Channel::Whatsapp';
});

const templates = computed(() => {
  if (!selectedInbox.value) return [];
  return getters['inboxes/getFilteredWhatsAppTemplates'].value(selectedInbox.value.id) || [];
});

const selectedTemplate = computed(() => {
  if (!parsedModel.value.template_name) return null;
  return templates.value.find(t => t.name === parsedModel.value.template_name);
});

const templateOptions = computed(() => {
  return templates.value.map(t => ({ id: t.name, name: `${t.name} (${t.language})` }));
});

const extractVariables = (componentType) => {
  if (!selectedTemplate.value) return [];
  const comp = selectedTemplate.value.components.find(c => c.type === componentType);
  if (!comp || !comp.text) return [];
  const matches = comp.text.match(/{{[^}]+}}/g) || [];
  return matches.map(m => m.replace(/{{|}}/g, ''));
};

const headerVariables = computed(() => extractVariables('HEADER'));
const bodyVariables = computed(() => extractVariables('BODY'));

const standardVariablesOptions = [
  { id: '{{first_name}}', name: 'Primeiro Nome ({{first_name}})' },
  { id: '{{last_name}}', name: 'Sobrenome ({{last_name}})' },
  { id: '{{full_name}}', name: 'Nome Completo ({{full_name}})' },
  { id: '{{email}}', name: 'E-mail ({{email}})' },
  { id: '{{phone}}', name: 'Telefone ({{phone}})' },
  { id: '{{city}}', name: 'Cidade ({{city}})' },
  { id: '{{country}}', name: 'País ({{country}})' },
  { id: '{{company_name}}', name: 'Empresa ({{company_name}})' },
  { id: '{{bio}}', name: 'Bio ({{bio}})' }
];

const autoFillOptions = computed(() => {
  const customOpts = customAttributes.value.map(attr => ({
    id: `{{ca_${attr.attribute_key}}}`,
    name: `${attr.attribute_display_name} ({{ca_${attr.attribute_key}}})`
  }));
  return [...standardVariablesOptions, ...customOpts];
});

const onTemplateChange = (eventOrValue) => {
  // Handles both select event and simple value
  const templateName = eventOrValue?.target ? eventOrValue.target.value : (eventOrValue?.id || eventOrValue);
  const template = templates.value.find(t => t.name === templateName);
  
  parsedModel.value = {
    ...parsedModel.value,
    template_name: templateName,
    language: template?.language,
    variables: {}
  };
};

const updateVariable = (index, value) => {
  const variables = { ...parsedModel.value.variables, [index]: value };
  parsedModel.value = { ...parsedModel.value, variables };
};

const isAutoFill = (index) => {
  const val = parsedModel.value.variables?.[index];
  return val === `{{${index}}}`;
};

const getSystemVariableLabel = (index) => {
  const formattedName = `{{${index}}}`;
  const match = autoFillOptions.value.find(opt => opt.id === formattedName);
  return match ? match.name : null;
};

const toggleAutoFill = (index, enable) => {
  if (enable) {
    updateVariable(index, `{{${index}}}`);
  } else {
    updateVariable(index, '');
  }
};

onMounted(() => {
  if (!inboxes.value.length || selectedInbox.value) {
    store.dispatch('inboxes/get');
  }
  store.dispatch('attributes/get');
  
  if (!Array.isArray(props.modelValue) || props.modelValue.length === 0) {
    emit('update:modelValue', [parsedModel.value]);
  }
});
</script>

<template>
  <div class="flex flex-col gap-4 mt-2 p-5 bg-n-alpha-1 rounded-xl border border-solid border-n-weak dark:border-n-strong">
    
    <!-- Validation Alerts -->
    <div v-if="!isInboxSelected" class="text-n-ruby-11 text-sm flex items-center gap-2 font-medium">
      <i class="i-ri-error-warning-line" />
      {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_REQUIRED') || 'Selecione uma Caixa de Entrada primeiro nas condições.' }}
    </div>
    
    <div v-else-if="!isWhatsAppCloud" class="text-n-ruby-11 text-sm flex items-center gap-2 font-medium">
      <i class="i-ri-error-warning-line" />
      {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_INVALID') || 'A caixa selecionada não é WhatsApp Oficial.' }}
    </div>

    <!-- Template Selection -->
    <div v-if="isWhatsAppCloud" class="flex flex-col gap-4">
      <div class="flex flex-col gap-2">
        <label class="text-sm font-semibold text-n-slate-12 m-0">{{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.SELECT_TEMPLATE') || 'Selecione o Template:' }}</label>
        <select
          :value="parsedModel.template_name"
          class="w-64 mb-0 text-sm bg-white dark:bg-slate-900 border border-solid border-slate-300 dark:border-slate-700 rounded-lg p-2"
          @change="onTemplateChange"
        >
          <option value="" disabled selected>Selecione uma opção...</option>
          <option v-for="opt in templateOptions" :key="opt.id" :value="opt.id">
            {{ opt.name }}
          </option>
        </select>
      </div>

      <!-- Selected Template Preview Box -->
      <div v-if="selectedTemplate" class="flex flex-col gap-4">
        <div class="bg-white dark:bg-n-solid-3 p-4 rounded-xl border border-solid border-n-weak dark:border-n-strong shadow-sm group">
          <div class="flex items-center justify-between mb-3 pb-3 border-b border-solid border-n-weak/50 dark:border-n-strong/50">
            <span class="font-semibold text-n-slate-12">{{ selectedTemplate.name }}</span>
            <span class="text-xs text-n-slate-10 font-medium">Idioma: {{ selectedTemplate.language }}</span>
          </div>
          
          <div class="flex flex-col gap-2 text-sm text-n-slate-12 whitespace-pre-wrap">
            <span v-if="selectedTemplate.components.find(c => c.type === 'HEADER')" class="font-semibold">
              {{ selectedTemplate.components.find(c => c.type === 'HEADER').text }}
            </span>
            <span>
              {{ selectedTemplate.components.find(c => c.type === 'BODY')?.text }}
            </span>
          </div>
          
          <div class="mt-4 pt-3 border-t border-solid border-n-weak/50 dark:border-n-strong/50 flex">
            <span class="text-xs text-n-slate-10 font-medium uppercase tracking-wider">
              Categoria: {{ selectedTemplate.category }}
            </span>
          </div>
        </div>

        <!-- Render Variables List -->
        <div v-if="headerVariables.length || bodyVariables.length" class="flex flex-col gap-5 mt-2">
          
          <template v-if="headerVariables.length">
            <div class="flex flex-col gap-3">
              <span class="text-sm font-semibold text-n-slate-12">Variáveis do Cabeçalho</span>
              <div v-for="vIndex in headerVariables" :key="'h' + vIndex" class="flex flex-col gap-2 p-3 bg-white dark:bg-n-solid-3 border border-solid border-n-weak dark:border-n-strong rounded-lg">
                <div class="flex items-center justify-between">
                  <span class="text-xs font-semibold text-n-slate-11">Variável {{ vIndex }}</span>
                  <div v-if="getSystemVariableLabel(vIndex)" class="flex items-center gap-2">
                    <span class="text-xs font-medium text-n-slate-11">Auto-preencher</span>
                    <Switch 
                      :model-value="isAutoFill(vIndex)"
                      @update:model-value="(val) => toggleAutoFill(vIndex, val)"
                    />
                  </div>
                </div>
                
                <woot-input
                  :model-value="isAutoFill(vIndex) ? '' : parsedModel.variables?.[vIndex]"
                  :disabled="isAutoFill(vIndex)"
                  :readonly="isAutoFill(vIndex)"
                  :placeholder="isAutoFill(vIndex) ? 'Preenchido com: ' + getSystemVariableLabel(vIndex) : 'Insira um valor fixo...'"
                  class="mb-0 mt-1"
                  :class="{ 'opacity-60 pointer-events-none cursor-not-allowed': isAutoFill(vIndex) }"
                  @input="(val) => !isAutoFill(vIndex) && updateVariable(vIndex, val)"
                />
              </div>
            </div>
          </template>

          <template v-if="bodyVariables.length">
            <div class="flex flex-col gap-3">
              <span class="text-sm font-semibold text-n-slate-12">Variáveis do Corpo da Mensagem</span>
              <div v-for="vIndex in bodyVariables" :key="'b' + vIndex" class="flex flex-col gap-2 p-3 bg-white dark:bg-n-solid-3 border border-solid border-n-weak dark:border-n-strong rounded-lg">
                <div class="flex items-center justify-between">
                  <span class="text-xs font-semibold text-n-slate-11">Variável {{ vIndex }}</span>
                  <div v-if="getSystemVariableLabel(vIndex)" class="flex items-center gap-2">
                    <span class="text-xs font-medium text-n-slate-11">Auto-preencher</span>
                    <Switch 
                      :model-value="isAutoFill(vIndex)"
                      @update:model-value="(val) => toggleAutoFill(vIndex, val)"
                    />
                  </div>
                </div>
                
                <woot-input
                  :model-value="isAutoFill(vIndex) ? '' : parsedModel.variables?.[vIndex]"
                  :disabled="isAutoFill(vIndex)"
                  :readonly="isAutoFill(vIndex)"
                  :placeholder="isAutoFill(vIndex) ? 'Preenchido com: ' + getSystemVariableLabel(vIndex) : 'Insira um valor fixo...'"
                  class="mb-0 mt-1"
                  :class="{ 'opacity-60 pointer-events-none cursor-not-allowed': isAutoFill(vIndex) }"
                  @input="(val) => !isAutoFill(vIndex) && updateVariable(vIndex, val)"
                />
              </div>
            </div>
          </template>

        </div>
      </div>
    </div>
  </div>
</template>
