<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AutomationsAPI from 'dashboard/api/automation';
import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTable, BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';
import { messageStamp } from 'shared/helpers/timeHelper';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  automationId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const getters = useStoreGetters();

const logs = ref([]);
const isFetching = ref(false);
const selectedLog = ref(null);
const showDetailsModal = ref(false);

const automation = computed(() => {
  if (!props.automationId) return null;
  return getters['automations/getAutomations'].value.find(
    a => a.id === Number(props.automationId)
  );
});

const automationName = computed(() => automation.value?.name || '');

const fetchLogs = async () => {
  if (!props.automationId) return;
  isFetching.value = true;
  try {
    const response = await AutomationsAPI.getLogs(props.automationId);
    logs.value = response.data.payload;
  } catch (error) {
    useAlert(t('AUTOMATION.LOGS.ERROR_FETCHING'));
  } finally {
    isFetching.value = false;
  }
};

watch(
  () => props.show,
  newShow => {
    if (newShow) {
      fetchLogs();
    }
  }
);

const readableDate = date => messageStamp(date, 'LLL d, yyyy HH:mm');

const getStatusClass = status => {
  switch (status) {
    case 'success': return 'text-n-success-11 bg-n-success-2';
    case 'failed': return 'text-n-ruby-11 bg-n-ruby-2';
    case 'ignored': return 'text-n-slate-11 bg-n-slate-2';
    default: return 'text-n-amber-11 bg-n-amber-2';
  }
};

const openLogDetails = log => {
  selectedLog.value = log;
  showDetailsModal.value = true;
};

const tableHeaders = computed(() => [
  t('AUTOMATION.LOGS.TABLE_HEADER.TIMESTAMP'),
  t('AUTOMATION.LOGS.TABLE_HEADER.STATUS'),
  t('AUTOMATION.LOGS.TABLE_HEADER.CONVERSATION'),
  t('AUTOMATION.LOGS.TABLE_HEADER.ACTIONS'),
]);

const onClose = () => {
  emit('close');
};
</script>

<template>
  <woot-modal :show="show" :on-close="onClose" width="80%">
    <div class="flex flex-col h-[80vh]">
      <woot-modal-header
        :header-title="$t('AUTOMATION.LOGS.TITLE')"
        :header-content="$t('AUTOMATION.LOGS.SUBTITLE', { automationName })"
      />
      
      <div class="flex-1 overflow-y-auto p-6">
        <div v-if="isFetching" class="flex items-center justify-center p-8">
          <woot-loading-indicator />
        </div>
        
        <div v-else-if="!logs.length" class="text-center p-8 text-n-slate-11">
          {{ $t('AUTOMATION.LOGS.NO_LOGS') }}
        </div>

        <BaseTable v-else :headers="tableHeaders" :items="logs">
          <template #row="{ items: logItems }">
            <BaseTableRow v-for="log in logItems" :key="log.id">
              <BaseTableCell>
                <span class="text-body-main text-n-slate-12">
                  {{ readableDate(log.created_at) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span
                  class="px-2 py-0.5 rounded-full text-xs font-medium"
                  :class="getStatusClass(log.status)"
                >
                  {{ $t(`AUTOMATION.LOGS.STATUS.${log.status.toUpperCase()}`) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span v-if="log.conversation" class="text-body-main text-n-link">
                  #{{ log.conversation.display_id }}
                </span>
                <span v-else>--</span>
              </BaseTableCell>
              <BaseTableCell align="end">
                <Button
                  icon="i-ri-information-line"
                  variant="clear"
                  size="sm"
                  @click="openLogDetails(log)"
                />
              </BaseTableCell>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>

      <div class="flex justify-end p-6 border-t border-n-weak">
        <Button
          :label="$t('AUTOMATION.FORM.CANCEL')"
          variant="clear"
          size="sm"
          @click="onClose"
        />
      </div>
    </div>

    <!-- Nested Details Modal -->
    <woot-modal
      :show="showDetailsModal"
      @update:show="val => showDetailsModal = val"
      :on-close="() => showDetailsModal = false"
    >
      <div class="p-6">
        <woot-modal-header :header-title="$t('AUTOMATION.LOGS.MODAL.TITLE')" />
        <div v-if="selectedLog" class="mt-4 space-y-4">
          <div v-if="selectedLog.error_message" class="p-4 bg-n-ruby-2 rounded-lg">
            <h4 class="text-sm font-semibold text-n-ruby-11 mb-1">
              {{ $t('AUTOMATION.LOGS.MODAL.ERROR_TITLE') }}
            </h4>
            <p class="text-sm text-n-ruby-11 font-mono break-all">
              {{ selectedLog.error_message }}
            </p>
          </div>

          <div>
            <h4 class="text-sm font-semibold text-n-slate-12 mb-2">
              {{ $t('AUTOMATION.LOGS.MODAL.ACTIONS_TITLE') }}
            </h4>
            <div class="border border-n-weak rounded-lg overflow-hidden max-h-60 overflow-y-auto">
              <table class="w-full text-left">
                <thead class="bg-n-slate-2 border-b border-n-weak text-xs uppercase text-n-slate-11 font-semibold sticky top-0">
                  <tr>
                    <th class="px-4 py-2">{{ $t('AUTOMATION.LOGS.MODAL.ACTION_COL') }}</th>
                    <th class="px-4 py-2 text-right">{{ $t('AUTOMATION.LOGS.MODAL.STATUS_COL') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-n-weak">
                  <tr v-for="(action, index) in selectedLog.actions_data" :key="index">
                    <td class="px-4 py-2 text-sm text-n-slate-12">
                      {{ action.action_name }}
                    </td>
                    <td class="px-4 py-2 text-right">
                      <span
                        class="px-2 py-0.5 rounded-full text-xs font-medium uppercase"
                        :class="getStatusClass(action.status)"
                      >
                        {{ action.status }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </woot-modal>
  </woot-modal>
</template>
