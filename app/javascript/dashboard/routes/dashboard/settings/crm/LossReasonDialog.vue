<script setup>
import { reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
  // Erro da API, como nome repetido (FA 9.3): aparece no campo de nome.
  errorMessage: { type: String, default: '' },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const dialogRef = ref(null);
// Motivo em edição; null ao criar.
const lossReason = ref(null);
const form = reactive({ name: '', description: '' });

const open = (record = null) => {
  lossReason.value = record;
  Object.assign(form, {
    name: record?.name || '',
    description: record?.description || '',
  });
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!form.name.trim()) return;
  emit('submit', {
    id: lossReason.value?.id,
    attributes: {
      name: form.name.trim(),
      description: form.description.trim() || null,
    },
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      lossReason
        ? t('CRM.SETTINGS.LOSS_REASONS.DIALOG.EDIT_TITLE')
        : t('CRM.SETTINGS.LOSS_REASONS.DIALOG.CREATE_TITLE')
    "
    :confirm-button-label="t('CRM.SETTINGS.SAVE')"
    :cancel-button-label="t('CRM.SETTINGS.CANCEL')"
    :disable-confirm-button="!form.name.trim()"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="t('CRM.SETTINGS.LOSS_REASONS.DIALOG.NAME')"
        :message="errorMessage"
        :message-type="errorMessage ? 'error' : 'info'"
        data-test="reason-name"
      />
      <TextArea
        v-model="form.description"
        :label="t('CRM.SETTINGS.LOSS_REASONS.DIALOG.DESCRIPTION')"
        :max-length="500"
        data-test="reason-description"
      />
    </div>
  </Dialog>
</template>
