<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  pipeline: { type: Object, default: null },
});

const emit = defineEmits(['move']);

const { t } = useI18n();

const dialogRef = ref(null);
const deal = ref(null);
const stageId = ref(null);

const open = target => {
  deal.value = target;
  stageId.value = null;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const confirm = () => {
  if (!stageId.value) return;
  emit('move', { deal: deal.value, stageId: stageId.value });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CRM_DEALS.MOVE.TITLE')"
    :description="
      t('CRM_DEALS.MOVE.DESCRIPTION', { pipeline: props.pipeline?.name })
    "
    :confirm-button-label="t('CRM_DEALS.MOVE.CONFIRM')"
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="!stageId"
    @confirm="confirm"
  >
    <label class="flex flex-col gap-1.5">
      <span class="text-label text-n-slate-12">{{
        t('CRM_DEALS.FORM.STAGE')
      }}</span>
      <select
        v-model="stageId"
        class="reset-base h-10 ps-3 pe-6 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
      >
        <option :value="null" disabled>{{ t('CRM_DEALS.MOVE.CHOOSE') }}</option>
        <option
          v-for="stage in props.pipeline?.stages || []"
          :key="stage.id"
          :value="stage.id"
          :disabled="stage.id === deal?.stage_id"
        >
          {{ stage.name }}
        </option>
      </select>
    </label>
  </Dialog>
</template>
