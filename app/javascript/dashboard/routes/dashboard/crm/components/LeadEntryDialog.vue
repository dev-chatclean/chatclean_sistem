<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmSettingsAPI from 'dashboard/api/crm/settings';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  hasDefaultPipeline: { type: Boolean, default: false },
});

const { t } = useI18n();

const dialogRef = ref(null);
const autoCreateDeals = ref(false);
const isSaving = ref(false);

const open = async () => {
  dialogRef.value?.open();
  try {
    const { data } = await CrmSettingsAPI.get();
    autoCreateDeals.value = data.crm_auto_create_deals;
  } catch (error) {
    useAlert(t('CRM_PIPELINES.API.FETCH_ERROR'));
  }
};

const save = async () => {
  isSaving.value = true;
  try {
    await CrmSettingsAPI.update({
      crm_auto_create_deals: autoCreateDeals.value,
    });
    useAlert(t('CRM_PIPELINES.API.SETTINGS_SUCCESS'));
    dialogRef.value?.close();
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CRM_PIPELINES.LEAD_ENTRY.TITLE')"
    :confirm-button-label="t('CRM_PIPELINES.FORM.SAVE')"
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :is-loading="isSaving"
    @confirm="save"
  >
    <div class="flex items-start gap-3 p-4 border rounded-xl border-n-weak">
      <Switch
        v-model="autoCreateDeals"
        :disabled="!props.hasDefaultPipeline"
        class="mt-0.5"
      />
      <div class="flex flex-col gap-1">
        <span class="text-heading-3 text-n-slate-12">
          {{ t('CRM_PIPELINES.LEAD_ENTRY.TOGGLE') }}
        </span>
        <span class="text-body-main text-n-slate-11">
          {{ t('CRM_PIPELINES.LEAD_ENTRY.DESCRIPTION') }}
        </span>
        <span
          v-if="!props.hasDefaultPipeline"
          class="text-body-main text-n-amber-11"
        >
          {{ t('CRM_PIPELINES.LEAD_ENTRY.NEEDS_DEFAULT') }}
        </span>
      </div>
    </div>
  </Dialog>
</template>
