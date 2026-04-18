<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';
import draggable from 'vuedraggable';

import AddLabel from './AddLabel.vue';
import EditLabel from './EditLabel.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLabel = ref({});
const searchQuery = ref('');

const records = computed(() => getters['labels/getLabels'].value);
const localRecords = ref([]);

watch(
  records,
  newRecords => {
    localRecords.value = [...newRecords];
  },
  { immediate: true, deep: true }
);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return localRecords.value;
  return picoSearch(localRecords.value, query, ['title', 'description']);
});

const uiFlags = computed(() => getters['labels/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedLabel.value.title}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  selectedLabel.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedLabel.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteLabel = async id => {
  try {
    await store.dispatch('labels/delete', id);
    useAlert(t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedLabel.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedLabel.value.id] = true;
  closeDeletePopup();
  deleteLabel(selectedLabel.value.id);
};

const tableHeaders = computed(() => {
  return [
    '',
    t('LABEL_MGMT.LIST.TABLE_HEADER.NAME'),
    t('LABEL_MGMT.LIST.TABLE_HEADER.DESCRIPTION'),
    t('LABEL_MGMT.LIST.TABLE_HEADER.COLOR'),
    t('LABEL_MGMT.LIST.TABLE_HEADER.ACTION'),
  ];
});

const onDragEnd = () => {
  const labelPositions = {};
  localRecords.value.forEach((label, index) => {
    labelPositions[label.id] = index;
  });
  store.dispatch('labels/reorder', labelPositions);
};

onBeforeMount(() => {
  store.dispatch('labels/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LABEL_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('LABEL_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('LABEL_MGMT.HEADER')"
        :description="$t('LABEL_MGMT.DESCRIPTION')"
        :link-text="$t('LABEL_MGMT.LEARN_MORE')"
        :search-placeholder="$t('LABEL_MGMT.SEARCH_PLACEHOLDER')"
        feature-name="labels"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('LABEL_MGMT.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('LABEL_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div v-if="filteredRecords.length" class="w-full">
        <table class="min-w-full table-auto divide-y divide-n-weak">
          <thead class="border-t border-n-weak">
            <tr>
              <th
                v-for="(header, index) in tableHeaders"
                :key="index"
                class="py-4 ltr:pr-4 rtl:pl-4 text-start text-heading-3 text-n-slate-12 capitalize"
              >
                {{ header }}
              </th>
            </tr>
          </thead>
          <draggable
            v-model="localRecords"
            tag="tbody"
            item-key="id"
            handle=".drag-handle"
            ghost-class="drag-ghost"
            :animation="300"
            class="divide-y divide-n-weak text-n-slate-11"
            @end="onDragEnd"
          >
            <template #item="{ element: label }">
              <BaseTableRow :item="label" class="transition-colors hover:bg-n-brand-1">
                <template #default>
                  <BaseTableCell class="drag-handle cursor-grab active:cursor-grabbing w-8">
                    <div class="flex items-center justify-center p-2 rounded-lg hover:bg-n-alpha-black-1 transitions-all duration-200 group">
                      <span class="i-ri-draggable text-n-slate-11 text-xl group-hover:text-n-brand-11" />
                    </div>
                  </BaseTableCell>

                  <BaseTableCell>
                    <span class="text-body-main font-medium text-n-slate-12">
                      {{ label.title }}
                    </span>
                  </BaseTableCell>

                  <BaseTableCell>
                    <span class="text-body-main text-n-slate-11">
                      {{ label.description || '-' }}
                    </span>
                  </BaseTableCell>

                  <BaseTableCell>
                    <div class="flex items-center">
                      <span
                        class="w-4 h-4 ltr:mr-2 rtl:ml-2 border border-solid rounded-full border-n-weak shadow-sm"
                        :style="{ backgroundColor: label.color }"
                      />
                      <span class="text-body-main text-n-slate-12 text-sm font-mono">
                        {{ label.color }}
                      </span>
                    </div>
                  </BaseTableCell>

                  <BaseTableCell align="end">
                    <div class="flex gap-3 justify-end flex-shrink-0">
                      <Button
                        v-tooltip.top="$t('LABEL_MGMT.FORM.EDIT')"
                        icon="i-woot-edit-pen"
                        slate
                        sm
                        :is-loading="loading[label.id]"
                        @click="openEditPopup(label)"
                      />
                      <Button
                        v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                        icon="i-woot-bin"
                        slate
                        sm
                        class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                        :is-loading="loading[label.id]"
                        @click="openDeletePopup(label)"
                      />
                    </div>
                  </BaseTableCell>
                </template>
              </BaseTableRow>
            </template>
          </draggable>
        </table>
      </div>
      <div v-else class="py-20 text-center text-body-main !text-base text-n-slate-11">
        {{ searchQuery ? $t('LABEL_MGMT.NO_RESULTS') : $t('LABEL_MGMT.LIST.404') }}
      </div>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddLabel @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditLabel :selected-response="selectedLabel" @close="hideEditPopup" />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('LABEL_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('LABEL_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>

<style lang="scss" scoped>
.drag-handle {
  user-select: none;
}

.drag-ghost {
  opacity: 0.4;
  background: var(--n-brand-5) !important;
  border-radius: 1rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.cursor-grab {
  cursor: grab;
}

.cursor-grabbing {
  cursor: grabbing;
}
</style>
