<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmSettingsAPI from 'dashboard/api/crm/settings';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { AI_FEATURES } from '../constants';
import { formatCurrency } from '../dealHelpers';

const { t } = useI18n();

const dialogRef = ref(null);
const isSaving = ref(false);
const ai = ref(null);
const monthCost = ref(0);

const capReached = computed(
  () =>
    Number(ai.value?.monthly_cap) > 0 &&
    monthCost.value >= Number(ai.value.monthly_cap)
);

const open = async () => {
  ai.value = null;
  dialogRef.value?.open();
  try {
    const { data } = await CrmSettingsAPI.get();
    ai.value = { ...data.ai };
    monthCost.value = data.ai_month_cost;
  } catch (error) {
    useAlert(t('CRM_PIPELINES.API.FETCH_ERROR'));
  }
};

const save = async () => {
  if (!ai.value || isSaving.value) return;
  isSaving.value = true;
  try {
    await CrmSettingsAPI.update({
      ai: { ...ai.value, monthly_cap: Number(ai.value.monthly_cap) || 0 },
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
    :title="t('CRM_PIPELINES.AI.TITLE')"
    :description="t('CRM_PIPELINES.AI.DESCRIPTION')"
    :confirm-button-label="t('CRM_PIPELINES.FORM.SAVE')"
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :is-loading="isSaving"
    @confirm="save"
  >
    <div v-if="ai" class="flex flex-col gap-3">
      <div
        v-for="feature in AI_FEATURES"
        :key="feature"
        class="flex items-start gap-3 p-3 border rounded-xl border-n-slate-6"
      >
        <Switch v-model="ai[feature]" class="mt-0.5" />
        <div class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t(`CRM_PIPELINES.AI.FEATURES.${feature.toUpperCase()}.TITLE`) }}
          </span>
          <span class="text-label-small text-n-slate-11">
            {{ t(`CRM_PIPELINES.AI.FEATURES.${feature.toUpperCase()}.HINT`) }}
          </span>
        </div>
      </div>
      <Input
        v-model="ai.monthly_cap"
        type="number"
        min="0"
        :label="t('CRM_PIPELINES.AI.MONTHLY_CAP.LABEL')"
        :message="t('CRM_PIPELINES.AI.MONTHLY_CAP.HINT')"
      />
      <span class="text-sm text-n-slate-11">
        {{
          t('CRM_PIPELINES.AI.MONTH_COST', { cost: formatCurrency(monthCost) })
        }}
      </span>
      <span v-if="capReached" class="text-sm text-n-ruby-11">
        {{ t('CRM_PIPELINES.AI.CAP_REACHED') }}
      </span>
    </div>
  </Dialog>
</template>
