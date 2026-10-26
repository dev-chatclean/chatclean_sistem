<script setup>
import { computed, nextTick, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import ClosingReasonsAPI from 'dashboard/api/chatclean/closingReasons';
import { closingRequest } from './closingRequest';

// Janela obrigatória de motivo ao fechar atendimento (US 16). Sem motivo ativo, o fechamento fica
// bloqueado e a janela pede para falar com um administrador (decisão do PO, 26/10/2026).
const { t } = useI18n();
const dialogRef = ref(null);
const reasons = ref([]);
const isFetching = ref(false);
const isSubmitting = ref(false);
const form = reactive({ reasonId: '', saleValue: '' });
let closed = false;

const reasonOptions = computed(() =>
  reasons.value.map(reason => ({ value: reason.id, label: reason.name }))
);
const selectedReason = computed(() =>
  reasons.value.find(reason => reason.id === form.reasonId)
);
const asksSaleValue = computed(() =>
  Boolean(selectedReason.value?.ask_sale_value)
);
const isSaleValueValid = computed(
  () => form.saleValue !== '' && Number(form.saleValue) >= 0
);
const canSubmit = computed(
  () =>
    Boolean(selectedReason.value) &&
    (!asksSaleValue.value || isSaleValueValid.value)
);
const hasNoReasons = computed(
  () => !isFetching.value && reasons.value.length === 0
);

const fetchReasons = async () => {
  isFetching.value = true;
  try {
    const { data } = await ClosingReasonsAPI.getActive();
    reasons.value = data.payload;
  } finally {
    isFetching.value = false;
  }
};

watch(
  () => closingRequest.isOpen,
  async isOpen => {
    if (!isOpen) return;
    closed = false;
    Object.assign(form, { reasonId: '', saleValue: '' });
    await nextTick();
    dialogRef.value?.open();
    fetchReasons().catch(() => useAlert(t('CHATCLEAN.CLOSING.LOAD_ERROR')));
  }
);

const onClose = () => {
  closingRequest.isOpen = false;
  closingRequest.finish?.(closed);
};

// Se o servidor recusar (ex.: motivo inativado com a janela aberta), a lista é recarregada (FA 16.1).
const handleConfirm = async () => {
  if (!canSubmit.value) return;
  isSubmitting.value = true;
  try {
    await closingRequest.submit({
      closingReasonId: form.reasonId,
      saleValue: asksSaleValue.value ? form.saleValue : null,
    });
    closed = true;
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CHATCLEAN.CLOSING.ERROR'));
    form.reasonId = '';
    await fetchReasons().catch(() => {});
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CHATCLEAN.CLOSING.TITLE')"
    :description="
      closingRequest.count > 1
        ? t('CHATCLEAN.CLOSING.BULK_DESCRIPTION', {
            count: closingRequest.count,
          })
        : t('CHATCLEAN.CLOSING.DESCRIPTION')
    "
    :confirm-button-label="t('CHATCLEAN.CLOSING.CONFIRM')"
    :disable-confirm-button="!canSubmit"
    :is-loading="isSubmitting"
    @confirm="handleConfirm"
    @close="onClose"
  >
    <p
      v-if="hasNoReasons"
      class="text-sm text-n-amber-11"
      data-test="closing-no-reasons"
    >
      {{ t('CHATCLEAN.CLOSING.NO_REASONS') }}
    </p>
    <div v-else class="flex flex-col gap-4">
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CHATCLEAN.CLOSING.REASON_LABEL') }}
        <Select
          v-model="form.reasonId"
          :options="reasonOptions"
          :placeholder="t('CHATCLEAN.CLOSING.REASON_PLACEHOLDER')"
          :disabled="isFetching"
          data-test="closing-reason"
        />
      </label>
      <Input
        v-if="asksSaleValue"
        v-model="form.saleValue"
        type="number"
        min="0"
        step="0.01"
        :label="t('CHATCLEAN.CLOSING.SALE_VALUE_LABEL')"
        :placeholder="t('CHATCLEAN.CLOSING.SALE_VALUE_PLACEHOLDER')"
        data-test="closing-sale-value"
      />
    </div>
  </Dialog>
</template>
