<script setup>
import { ref, computed, toRef } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useFunctionGetter, useStore } from 'dashboard/composables/store';
import {
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  findComponentByType,
} from 'dashboard/helper/templateHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';

const props = defineProps({
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSelect', 'onCreate']);

const { t } = useI18n();
const store = useStore();
const { isAdmin } = useAdmin();

const query = ref('');
const isRefreshing = ref(false);
const selectedTab = ref('all');

const whatsAppTemplateMessages = useFunctionGetter(
  'inboxes/getAllSupportedWhatsAppTemplates',
  toRef(props, 'inboxId')
);

const tabs = computed(() => [
  { key: 'approved', label: t('WHATSAPP_TEMPLATES.PICKER.TABS.APPROVED') || 'Aprovados' },
  { key: 'pending', label: t('WHATSAPP_TEMPLATES.PICKER.TABS.PENDING') || 'Pendentes' },
  { key: 'rejected', label: t('WHATSAPP_TEMPLATES.PICKER.TABS.REJECTED') || 'Reprovados' },
  { key: 'all', label: t('WHATSAPP_TEMPLATES.PICKER.TABS.ALL') || 'Todos' },
]);

const templatesByStatus = computed(() => {
  if (selectedTab.value === 'all') return whatsAppTemplateMessages.value;
  
  return whatsAppTemplateMessages.value.filter(template => {
    const status = template.status ? template.status.toLowerCase() : '';
    if (selectedTab.value === 'approved') return status === 'approved';
    if (selectedTab.value === 'rejected') return status === 'rejected';
    // Se "pending", consideramos qualquer coisa que não seja approved ou rejected (ex: pending_approval, in_appeal, paused, disabled)
    return status !== 'approved' && status !== 'rejected';
  });
});

const filteredTemplateMessages = computed(() => {
  const searchQuery = query.value.toLowerCase().trim();
  const templates = templatesByStatus.value;
  
  if (!searchQuery) {
    return templates;
  }

  const nameMatches = [];
  const bodyMatches = [];

  templates.forEach(template => {
    if (template.name.toLowerCase().includes(searchQuery)) {
      nameMatches.push(template);
    } else {
      const textBody = findComponentByType(template, COMPONENT_TYPES.BODY)?.text || '';
      if (textBody.toLowerCase().includes(searchQuery)) {
        bodyMatches.push(template);
      }
    }
  });

  // Retorna os templates que dão match no nome primeiro, 
  // seguidos pelos templates que deram match no conteúdo da mensagem.
  return [...nameMatches, ...bodyMatches];
});

const getTemplateBody = template => {
  return findComponentByType(template, COMPONENT_TYPES.BODY)?.text || '';
};

const getTemplateHeader = template => {
  return findComponentByType(template, COMPONENT_TYPES.HEADER);
};

const getTemplateFooter = template => {
  return findComponentByType(template, COMPONENT_TYPES.FOOTER);
};

const getTemplateButtons = template => {
  return findComponentByType(template, COMPONENT_TYPES.BUTTONS);
};

const hasMediaContent = template => {
  const header = getTemplateHeader(template);
  return header && MEDIA_FORMATS.includes(header.format);
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', props.inboxId);
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_ERROR'));
  } finally {
    isRefreshing.value = false;
  }
};

const handleTemplateSelect = template => {
  const status = template.status ? template.status.toLowerCase() : '';
  if (status === 'approved') {
    emit('onSelect', template);
  } else {
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.ALERT_ONLY_APPROVED') || 'Apenas templates aprovados podem ser enviados.');
  }
};

const getStatusColorClass = (status = '') => {
  const lowercaseStatus = status.toLowerCase();
  switch (lowercaseStatus) {
    case 'approved':
      return 'text-n-grass-9 bg-n-grass-3 border-n-grass-6';
    case 'pending':
    case 'pending_approval':
    case 'in_appeal':
      return 'text-n-amber-9 bg-n-amber-3 border-n-amber-6';
    case 'rejected':
    case 'paused':
    case 'disabled':
      return 'text-n-ruby-9 bg-n-ruby-3 border-n-ruby-6';
    default:
      return 'text-n-slate-9 bg-n-slate-3 border-n-slate-6';
  }
};
</script>

<template>
  <div class="w-full">
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
        />
      </div>
      <button
        :disabled="isRefreshing"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed"
        :title="t('WHATSAPP_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-n-slate-12 size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
      </button>
      <button
        v-if="isAdmin"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-brand/10 dark:hover:bg-n-brand/20 transition-all border-0 cursor-pointer"
        :title="t('WHATSAPP_TEMPLATES.PICKER.CREATE_BUTTON') || 'Criar Template'"
        @click="emit('onCreate')"
      >
        <Icon
          icon="i-lucide-plus"
          class="text-n-brand size-5"
        />
      </button>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 mb-2.5 p-1 bg-n-alpha-black2 rounded-lg" role="tablist">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        role="tab"
        :aria-selected="selectedTab === tab.key"
        :class="[
          'flex-1 px-2 py-1.5 text-xs font-medium rounded-md transition-all cursor-pointer',
          selectedTab === tab.key 
            ? 'bg-white dark:bg-slate-700 text-n-slate-12 shadow-sm' 
            : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1 border-transparent bg-transparent'
        ]"
        @click="selectedTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          class="block p-2.5 w-full text-left rounded-lg cursor-pointer hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
          :class="template.status?.toLowerCase() !== 'approved' ? 'opacity-70' : ''"
          @click="handleTemplateSelect(template)"
        >
          <div>
            <div class="flex justify-between items-center mb-2.5">
              <div class="flex items-center gap-2">
                 <p class="text-sm">
                  {{ template.name }}
                </p>
                <span
                  v-if="template.status"
                  class="px-1.5 py-0.5 text-[10px] uppercase font-bold rounded-md border"
                  :class="getStatusColorClass(template.status)"
                >
                  {{ template.status }}
                </span>
              </div>
              <span
                class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
              >
                {{ t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE') }}:
                {{ template.language }}
              </span>
            </div>
            <!-- Header -->
            <div v-if="getTemplateHeader(template)" class="mb-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.HEADER') || 'HEADER' }}
              </p>
              <div
                v-if="getTemplateHeader(template).format === 'TEXT'"
                class="text-sm label-body"
              >
                {{ getTemplateHeader(template).text }}
              </div>
              <div
                v-else-if="hasMediaContent(template)"
                class="text-sm italic text-n-slate-11"
              >
                {{
                  t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT', {
                    format: getTemplateHeader(template).format,
                  }) ||
                  `${getTemplateHeader(template).format} ${t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT_FALLBACK')}`
                }}
              </div>
            </div>

            <!-- Body -->
            <div>
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.BODY') || 'BODY' }}
              </p>
              <p class="text-sm label-body">{{ getTemplateBody(template) }}</p>
            </div>

            <!-- Footer -->
            <div v-if="getTemplateFooter(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.FOOTER') || 'FOOTER' }}
              </p>
              <p class="text-sm label-body">
                {{ getTemplateFooter(template).text }}
              </p>
            </div>

            <!-- Buttons -->
            <div v-if="getTemplateButtons(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.BUTTONS') || 'BUTTONS' }}
              </p>
              <div class="flex flex-wrap gap-1 mt-1">
                <span
                  v-for="button in getTemplateButtons(template).buttons"
                  :key="button.text"
                  class="px-2 py-1 text-xs rounded bg-n-slate-3 text-n-slate-12"
                >
                  {{ button.text }}
                </span>
              </div>
            </div>

            <div class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('WHATSAPP_TEMPLATES.PICKER.CATEGORY') || 'CATEGORY' }}
              </p>
              <p class="text-sm">{{ template.category }}</p>
            </div>
          </div>
        </button>
        <hr
          v-if="i != filteredTemplateMessages.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredTemplateMessages.length" class="py-8 text-center">
        <div v-if="query && whatsAppTemplateMessages.length">
          <p>
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <div v-else-if="!whatsAppTemplateMessages.length" class="space-y-4">
          <p class="text-n-slate-11">
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
