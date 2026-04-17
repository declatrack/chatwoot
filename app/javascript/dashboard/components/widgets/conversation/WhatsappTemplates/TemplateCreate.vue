<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import VariableInsertionModal from './VariableInsertionModal.vue';

const props = defineProps({
  inboxId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['back', 'success']);

const { t } = useI18n();
const store = useStore();

const templateName = ref('');
const category = ref('MARKETING');
const language = ref('pt_BR');
const headerText = ref('');
const bodyText = ref('');
const footerText = ref('');
const isSaving = ref(false);
const isVariableModalOpen = ref(false);
const activeInput = ref('body');
const variableExamples = ref({});
const headerInputRef = ref(null);
const bodyTextareaRef = ref(null);
const savedCursorPos = ref(0);

const extractedVariables = computed(() => {
  const matchesBody = bodyText.value.match(/{{([^{}]+)}}/g) || [];
  const matchesHeader = headerText.value.match(/{{([^{}]+)}}/g) || [];
  const allMatches = [...matchesBody, ...matchesHeader];
  return allMatches.length ? [...new Set(allMatches.map(m => m.replace(/[{}]/g, '').trim()))] : [];
});

watch(extractedVariables, (newVars) => {
  newVars.forEach(v => {
    if (!variableExamples.value[v]) {
      variableExamples.value[v] = getExampleValue(v);
    }
  });
});

watch(templateName, (newVal) => {
  if (!newVal) return;
  const formatted = newVal
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') 
    .replace(/\s+/g, '_')            
    .replace(/[^\w]/gi, '');         
    
  if (templateName.value !== formatted) {
    templateName.value = formatted;
  }
});

const categories = [
  { label: 'Marketing', value: 'MARKETING' },
  { label: 'Utility', value: 'UTILITY' },
];

const languages = [
  { label: 'Portuguese (BR)', value: 'pt_BR' },
  { label: 'English (US)', value: 'en_US' },
  { label: 'Spanish', value: 'es' },
  { label: 'French', value: 'fr' },
  { label: 'German', value: 'de' },
];

const openVariableModal = (input) => {
  activeInput.value = input;
  // Save cursor position before the modal opens and the element loses focus
  const el = input === 'header' ? headerInputRef.value : bodyTextareaRef.value;
  savedCursorPos.value = el?.selectionStart ?? (input === 'header' ? headerText.value.length : bodyText.value.length);
  isVariableModalOpen.value = true;
};

const insertVariable = async variable => {
  const tag = `{{${variable}}}`;
  const pos = savedCursorPos.value;

  if (activeInput.value === 'header') {
    const before = headerText.value.slice(0, pos);
    const after = headerText.value.slice(pos);
    headerText.value = before + tag + after;
    await nextTick();
    const newPos = pos + tag.length;
    headerInputRef.value?.setSelectionRange(newPos, newPos);
    headerInputRef.value?.focus();
  } else {
    const before = bodyText.value.slice(0, pos);
    const after = bodyText.value.slice(pos);
    bodyText.value = before + tag + after;
    await nextTick();
    const newPos = pos + tag.length;
    bodyTextareaRef.value?.setSelectionRange(newPos, newPos);
    bodyTextareaRef.value?.focus();
  }
};

const getExampleValue = varName => {
  const examples = {
    first_name: 'John',
    last_name: 'Doe',
    full_name: 'John Doe',
    email: 'john@example.com',
    phone: '+5511999999999',
    city: 'São Paulo',
    country: 'Brazil',
    company_name: 'Chatwoot',
    bio: 'Software Engineer',
  };
  return examples[varName.toLowerCase()] || 'example_value';
};

const handleSave = async () => {
  const body = bodyText.value;
  if (!templateName.value || !body) {
    useAlert(t('WHATSAPP_TEMPLATES.CREATE.ERRORS.REQUIRED_FIELDS'));
    return;
  }

  // Strict Meta Validations
  if (body.length > 1024) {
    useAlert('O corpo da mensagem excedeu o limite de 1024 caracteres.');
    return;
  }
  if (headerText.value) {
    if (headerText.value.length > 60) {
      useAlert('O cabeçalho excedeu o limite de 60 caracteres.');
      return;
    }
    const headerMatches = headerText.value.match(/{{([^{}]+)}}/g);
    if (headerMatches && headerMatches.length > 1) {
      useAlert('O cabeçalho pode conter no máximo uma (1) variável.');
      return;
    }
  }
  if (footerText.value.length > 60) {
    useAlert('O rodapé excedeu o limite de 60 caracteres.');
    return;
  }
  if (/^\{\{.+?\}\}/.test(body.trim())) {
    useAlert('A mensagem não pode começar com uma variável.');
    return;
  }
  if (/\{\{.+?\}\}$/.test(body.trim())) {
    useAlert('A mensagem não pode terminar com uma variável.');
    return;
  }
  if (/\n{3,}/.test(body)) {
    useAlert('O formato não permite mais de duas quebras de linha consecutivas.');
    return;
  }
  if (/\t| {5,}/.test(body)) {
    useAlert('Não são permitidos tabulações ou mais de 4 espaços consecutivos.');
    return;
  }

  // Validação de tamanho máximo da variável (20 caracteres)
  const allText = body + '\n' + (headerText.value || '');
  const matches = allText.match(/{{([^{}]+)}}/g);
  if (matches) {
    for (const match of matches) {
      const varName = match.replace(/[{}]/g, '').trim();
      if (varName.length > 20) {
        useAlert(`A variável "{{${varName}}}" tem ${varName.length} caracteres. O limite máximo é 20 caracteres.`);
        return;
      }
    }
  }

  const missingExamples = extractedVariables.value.filter(v => !variableExamples.value[v] || variableExamples.value[v].trim() === '');
  if (missingExamples.length > 0) {
    useAlert('Por favor, forneça exemplos para todas as variáveis.');
    return;
  }

  isSaving.value = true;
  try {
    const components = [];

    if (headerText.value) {
      const headerComponent = { type: 'HEADER', format: 'TEXT', text: headerText.value };
      
      const headerExamples = [];
      const headerUsedVariables = new Set();
      
      const metaHeaderText = headerText.value.replace(/{{([^{}]+)}}/g, (match, p1) => {
        const varName = p1.trim();
        if (!headerUsedVariables.has(varName)) {
          headerUsedVariables.add(varName);
          headerExamples.push({
            param_name: varName,
            example: variableExamples.value[varName] || varName,
          });
        }
        return `{{${varName}}}`;
      });

      headerComponent.text = metaHeaderText;

      if (headerExamples.length > 0) {
        headerComponent.example = {
          header_text_named_params: headerExamples,
        };
      }

      components.push(headerComponent);
    }

    // Body processing: use Meta named parameters format ({{first_name}} stays as {{first_name}})
    const examples = [];
    const usedVariables = new Set();
    
    const metaBodyText = body.replace(/{{([^{}]+)}}/g, (match, p1) => {
      const varName = p1.trim();
      if (!usedVariables.has(varName)) {
        usedVariables.add(varName);
        examples.push({
          param_name: varName,
          example: variableExamples.value[varName] || varName,
        });
      }
      return `{{${varName}}}`;
    });

    const bodyComponent = {
      type: 'BODY',
      text: metaBodyText,
    };

    if (examples.length > 0) {
      bodyComponent.example = {
        body_text_named_params: examples,
      };
    }

    components.push(bodyComponent);

    if (footerText.value) {
      components.push({ type: 'FOOTER', text: footerText.value });
    }

    await store.dispatch('inboxes/createWhatsAppTemplate', {
      inboxId: props.inboxId,
      template: {
        name: templateName.value,
        category: category.value,
        language: language.value,
        parameter_format: 'named',
        components,
      },
    });

    useAlert(t('WHATSAPP_TEMPLATES.CREATE.SUCCESS') || 'Template submitted successfully');
    emit('success');
  } catch (error) {
    const errorReason = error.response?.data?.error || error.message;
    const defaultMessage = t('WHATSAPP_TEMPLATES.CREATE.ERROR') || 'Falha ao criar o template';
    useAlert(`${defaultMessage} - ${errorReason}`);
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full bg-n-background p-4 overflow-y-auto">
    <div class="flex items-center gap-2 mb-6">
      <Button
        variant="ghost"
        size="sm"
        icon="i-lucide-arrow-left"
        @click="emit('back')"
      />
      <h3 class="text-lg font-semibold text-n-slate-12">
        Criar Template WhatsApp
      </h3>
    </div>

    <div class="space-y-6">
      <!-- Name -->
      <div>
        <label class="block text-sm font-medium text-n-slate-11 mb-1.5">
          Nome do Template (apenas letras, números e underscores)
        </label>
        <input
          v-model="templateName"
          type="text"
          placeholder="ex: boas_vindas_cliente"
          class="w-full h-10 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak focus:outline-n-brand text-n-slate-12 text-sm transition-all"
        />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <!-- Category -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1.5">
            Categoria
          </label>
          <ComboBox v-model="category" :options="categories" />
        </div>
        <!-- Language -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1.5">
            Idioma
          </label>
          <ComboBox v-model="language" :options="languages" />
        </div>
      </div>

      <!-- Header -->
      <div>
        <div class="flex justify-between items-end mb-1.5">
          <label class="block text-sm font-medium text-n-slate-11">
            Cabeçalho (Opcional)
          </label>
          <Button
            :label="t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.BUTTON') || 'Inserir Variável'"
            variant="ghost"
            size="xs"
            color="slate"
            icon="i-lucide-plus"
            @click="openVariableModal('header')"
          />
        </div>
        <input
          ref="headerInputRef"
          v-model="headerText"
          type="text"
          placeholder="Texto do cabeçalho..."
          class="w-full h-10 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak focus:outline-n-brand text-n-slate-12 text-sm transition-all"
        />
      </div>

      <!-- Body -->
      <div>
        <div class="flex justify-between items-end mb-1.5">
          <label class="block text-sm font-medium text-n-slate-11">
            Corpo da Mensagem (Obrigatório)
          </label>
        </div>
        <textarea
          ref="bodyTextareaRef"
          v-model="bodyText"
          rows="5"
          placeholder="Digite o conteúdo da mensagem..."
          class="w-full p-3 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak focus:outline-n-brand text-n-slate-12 text-sm transition-all resize-none"
        />
        <!-- Variable Buttons -->
        <div class="mt-3">
          <Button
            :label="t('WHATSAPP_TEMPLATES.CREATE.VARIABLES.BUTTON') || 'Inserir Variável'"
            variant="outline"
            size="sm"
            color="slate"
            icon="i-lucide-plus"
            @click="openVariableModal('body')"
          />
        </div>
      </div>

      <!-- Variable Examples -->
      <div v-if="extractedVariables.length > 0" class="p-3 bg-n-alpha-1 rounded-lg border border-n-weak">
        <label class="block text-sm font-medium text-n-slate-11 mb-2">
          Exemplos de Variáveis (Obrigatório pela Meta)
        </label>
        <p class="text-xs text-n-slate-11 mb-3">Forneça valores de exemplo reais para as variáveis. A Meta exige isso para aprovação.</p>
        <div class="space-y-3">
          <div v-for="variable in extractedVariables" :key="variable" class="flex flex-col gap-1">
            <label class="text-xs text-n-slate-12">
              <code>{{ '{' + '{' + variable + '}' + '}' }}</code>
            </label>
            <input
              v-model="variableExamples[variable]"
              type="text"
              :placeholder="`Exemplo para ${variable}`"
              class="w-full h-8 px-2 rounded bg-n-alpha-black2 outline outline-1 outline-n-weak focus:outline-n-brand text-n-slate-12 text-sm"
            />
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div>
        <label class="block text-sm font-medium text-n-slate-11 mb-1.5">
          Rodapé (Opcional)
        </label>
        <input
          v-model="footerText"
          type="text"
          placeholder="Texto de apoio no rodapé..."
          class="w-full h-10 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak focus:outline-n-brand text-n-slate-12 text-sm transition-all"
        />
      </div>

      <!-- Buttons Info -->
      <div class="p-3 bg-n-alpha-1 rounded-lg border border-n-weak">
        <p class="text-xs text-n-slate-11">
          <Icon icon="i-lucide-info" class="inline mr-1" />
          Nota: Botões interativos e cabeçalhos de mídia podem ser configurados posteriormente no gerenciador da Meta. Esta interface foca no conteúdo textual principal.
        </p>
      </div>

      <div class="flex justify-end pt-4 pb-2 border-t border-n-weak">
        <Button
          label="Cancelar"
          variant="ghost"
          @click="emit('back')"
        />
        <Button
          label="Submeter para Aprovação"
          color="blue"
          icon="i-lucide-send"
          :is-loading="isSaving"
          @click="handleSave"
        />
      </div>
    </div>

    <!-- Variable Insertion Modal -->
    <VariableInsertionModal
      v-model:show="isVariableModalOpen"
      @insert="insertVariable"
    />
  </div>
</template>
