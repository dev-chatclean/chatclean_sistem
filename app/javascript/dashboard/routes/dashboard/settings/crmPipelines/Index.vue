<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmSettingsAPI from 'dashboard/api/crm/settings';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import PipelineFormDialog from './PipelineFormDialog.vue';

const { t } = useI18n();

const pipelines = ref([]);
const autoCreateDeals = ref(false);
const isFetching = ref(true);
const isSaving = ref(false);
const isUpdatingSettings = ref(false);
const pipelineToDelete = ref(null);
const formDialogRef = ref(null);
const deleteDialogRef = ref(null);

const hasDefaultPipeline = computed(() =>
  pipelines.value.some(pipeline => pipeline.is_default)
);

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const fetchData = async () => {
  isFetching.value = true;
  try {
    const [{ data: pipelineData }, { data: settingsData }] = await Promise.all([
      CrmPipelinesAPI.get(),
      CrmSettingsAPI.get(),
    ]);
    pipelines.value = pipelineData.payload;
    autoCreateDeals.value = settingsData.crm_auto_create_deals;
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.FETCH_ERROR');
  } finally {
    isFetching.value = false;
  }
};

const openCreateDialog = () => formDialogRef.value?.open();
const openEditDialog = pipeline => formDialogRef.value?.open(pipeline);

const savePipeline = async ({ id, name }) => {
  isSaving.value = true;
  try {
    if (id) {
      await CrmPipelinesAPI.update(id, { pipeline: { name } });
      useAlert(t('CRM_PIPELINES.API.UPDATE_SUCCESS'));
    } else {
      await CrmPipelinesAPI.create({ pipeline: { name } });
      useAlert(t('CRM_PIPELINES.API.CREATE_SUCCESS'));
    }
    formDialogRef.value?.close();
    await fetchData();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const setAsDefault = async pipeline => {
  try {
    await CrmPipelinesAPI.update(pipeline.id, {
      pipeline: { is_default: true },
    });
    useAlert(t('CRM_PIPELINES.API.DEFAULT_SUCCESS', { name: pipeline.name }));
    await fetchData();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  }
};

const openDeleteDialog = pipeline => {
  pipelineToDelete.value = pipeline;
  deleteDialogRef.value?.open();
};

const confirmDelete = async () => {
  isSaving.value = true;
  try {
    await CrmPipelinesAPI.delete(pipelineToDelete.value.id);
    useAlert(t('CRM_PIPELINES.API.DELETE_SUCCESS'));
    deleteDialogRef.value?.close();
    await fetchData();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.DELETE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const updateAutoCreateDeals = async value => {
  isUpdatingSettings.value = true;
  try {
    const { data } = await CrmSettingsAPI.update({
      crm_auto_create_deals: value,
    });
    autoCreateDeals.value = data.crm_auto_create_deals;
    useAlert(t('CRM_PIPELINES.API.SETTINGS_SUCCESS'));
  } catch (error) {
    autoCreateDeals.value = !value;
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  } finally {
    isUpdatingSettings.value = false;
  }
};

onMounted(fetchData);
</script>

<template>
  <SettingsLayout
    :is-loading="isFetching"
    :loading-message="t('CRM_PIPELINES.LOADING')"
    :no-records-found="!pipelines.length"
    :no-records-message="t('CRM_PIPELINES.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CRM_PIPELINES.HEADER')"
        :description="t('CRM_PIPELINES.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('CRM_PIPELINES.CREATE_BUTTON')"
            icon="i-lucide-plus"
            size="sm"
            @click="openCreateDialog"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div class="flex flex-col gap-6">
        <div
          class="flex items-start justify-between gap-4 p-4 border rounded-xl border-n-weak bg-n-solid-1"
        >
          <div class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_PIPELINES.AUTO_CREATE.TITLE') }}
            </span>
            <span class="text-body-main text-n-slate-11">
              {{ t('CRM_PIPELINES.AUTO_CREATE.DESCRIPTION') }}
            </span>
          </div>
          <Switch
            v-model="autoCreateDeals"
            :disabled="isUpdatingSettings || !hasDefaultPipeline"
            @change="updateAutoCreateDeals"
          />
        </div>

        <ul class="flex flex-col gap-3">
          <li
            v-for="pipeline in pipelines"
            :key="pipeline.id"
            class="flex flex-col gap-3 p-4 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <div class="flex items-center justify-between gap-3">
              <div class="flex items-center gap-2 min-w-0">
                <span class="i-lucide-funnel size-4 text-n-slate-11 shrink-0" />
                <span class="text-heading-3 text-n-slate-12 truncate">
                  {{ pipeline.name }}
                </span>
                <span
                  v-if="pipeline.is_default"
                  class="px-2 py-0.5 rounded-md text-label-small bg-n-brand/10 text-n-blue-11"
                >
                  {{ t('CRM_PIPELINES.DEFAULT_BADGE') }}
                </span>
              </div>
              <div class="flex items-center gap-2 shrink-0">
                <Button
                  v-if="!pipeline.is_default"
                  :label="t('CRM_PIPELINES.SET_DEFAULT')"
                  slate
                  faded
                  sm
                  @click="setAsDefault(pipeline)"
                />
                <Button
                  v-tooltip.top="t('CRM_PIPELINES.EDIT')"
                  icon="i-woot-edit-pen"
                  slate
                  sm
                  @click="openEditDialog(pipeline)"
                />
                <Button
                  v-tooltip.top="
                    pipeline.is_default
                      ? t('CRM_PIPELINES.DELETE_DEFAULT_BLOCKED')
                      : t('CRM_PIPELINES.DELETE')
                  "
                  icon="i-woot-bin"
                  slate
                  sm
                  :disabled="pipeline.is_default"
                  class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                  @click="openDeleteDialog(pipeline)"
                />
              </div>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              <span
                v-for="stage in pipeline.stages"
                :key="stage.id"
                class="flex items-center gap-1.5 px-2 py-1 border rounded-lg border-n-weak text-label-small text-n-slate-12"
              >
                <span
                  class="rounded-sm size-2"
                  :style="{ backgroundColor: stage.color }"
                />
                {{ stage.name }}
              </span>
            </div>
          </li>
        </ul>
      </div>
    </template>
  </SettingsLayout>

  <PipelineFormDialog
    ref="formDialogRef"
    :is-loading="isSaving"
    @submit="savePipeline"
  />

  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="t('CRM_PIPELINES.DELETE_CONFIRM.TITLE')"
    :description="
      t('CRM_PIPELINES.DELETE_CONFIRM.MESSAGE', {
        name: pipelineToDelete?.name,
      })
    "
    :confirm-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.YES')"
    :cancel-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.NO')"
    :is-loading="isSaving"
    @confirm="confirmDelete"
  />
</template>
