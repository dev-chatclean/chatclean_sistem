<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  dealTitle: { type: String, default: '' },
  lossReasons: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm', 'cancel']);

const { t } = useI18n();
const dialogRef = ref(null);
const lossReasonId = ref('');
const lossDetails = ref('');
// Fechar depois de confirmar não deve ser tratado como cancelamento.
const confirmed = ref(false);

const reasonOptions = computed(() =>
  props.lossReasons.map(reason => ({ value: reason.id, label: reason.name }))
);

const open = () => {
  lossReasonId.value = '';
  lossDetails.value = '';
  confirmed.value = false;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!lossReasonId.value) return;
  confirmed.value = true;
  emit('confirm', {
    lossReasonId: Number(lossReasonId.value),
    lossDetails: lossDetails.value.trim(),
  });
};

const handleClose = () => {
  if (!confirmed.value) emit('cancel');
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CRM.KANBAN.LOSS_MODAL.TITLE')"
    :description="t('CRM.KANBAN.LOSS_MODAL.DESCRIPTION', { title: dealTitle })"
    :confirm-button-label="t('CRM.KANBAN.LOSS_MODAL.CONFIRM')"
    :cancel-button-label="t('CRM.KANBAN.LOSS_MODAL.CANCEL')"
    :disable-confirm-button="!lossReasonId"
    :is-loading="isLoading"
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CRM.KANBAN.LOSS_MODAL.REASON_LABEL') }}
        <Select
          v-model="lossReasonId"
          :options="reasonOptions"
          :placeholder="t('CRM.KANBAN.LOSS_MODAL.REASON_PLACEHOLDER')"
          data-test="loss-reason"
        />
      </label>
      <p v-if="!lossReasons.length" class="text-sm text-n-ruby-11">
        {{ t('CRM.KANBAN.LOSS_MODAL.NO_REASONS') }}
      </p>
      <TextArea
        v-model="lossDetails"
        :label="t('CRM.KANBAN.LOSS_MODAL.DETAILS_LABEL')"
        :placeholder="t('CRM.KANBAN.LOSS_MODAL.DETAILS_PLACEHOLDER')"
        :max-length="1000"
        show-character-count
        auto-height
      />
    </div>
  </Dialog>
</template>
