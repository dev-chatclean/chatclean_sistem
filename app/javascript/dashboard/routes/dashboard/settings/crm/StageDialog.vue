<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
  errorMessage: { type: String, default: '' },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const dialogRef = ref(null);
// Estágio em edição; null ao criar.
const stage = ref(null);
const form = reactive({ name: '', probability: 0 });

// Ganho e Perdido só podem ser renomeados (CA 9.4).
const isClosingStage = computed(() =>
  ['won', 'lost'].includes(stage.value?.status)
);

const isProbabilityValid = computed(
  () =>
    Number.isInteger(Number(form.probability)) &&
    form.probability !== '' &&
    form.probability >= 0 &&
    form.probability <= 100
);

const canSubmit = computed(
  () => form.name.trim() && (isClosingStage.value || isProbabilityValid.value)
);

const open = (record = null) => {
  stage.value = record;
  Object.assign(form, {
    name: record?.name || '',
    probability: record?.probability ?? 0,
  });
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!canSubmit.value) return;
  const attributes = { name: form.name.trim() };
  if (!isClosingStage.value) attributes.probability = Number(form.probability);
  emit('submit', { id: stage.value?.id, attributes });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      stage
        ? t('CRM.SETTINGS.STAGES.DIALOG.EDIT_TITLE')
        : t('CRM.SETTINGS.STAGES.DIALOG.CREATE_TITLE')
    "
    :description="
      isClosingStage ? t('CRM.SETTINGS.STAGES.DIALOG.CLOSING_HINT') : ''
    "
    :confirm-button-label="t('CRM.SETTINGS.SAVE')"
    :cancel-button-label="t('CRM.SETTINGS.CANCEL')"
    :disable-confirm-button="!canSubmit"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="t('CRM.SETTINGS.STAGES.DIALOG.NAME')"
        :message="errorMessage"
        :message-type="errorMessage ? 'error' : 'info'"
        data-test="stage-name"
      />
      <Input
        v-model="form.probability"
        type="number"
        max="100"
        step="1"
        :label="t('CRM.SETTINGS.STAGES.DIALOG.PROBABILITY')"
        :disabled="isClosingStage"
        :message="
          isProbabilityValid || isClosingStage
            ? ''
            : t('CRM.SETTINGS.STAGES.DIALOG.PROBABILITY_INVALID')
        "
        :message-type="isProbabilityValid || isClosingStage ? 'info' : 'error'"
        data-test="stage-probability"
      />
    </div>
  </Dialog>
</template>
