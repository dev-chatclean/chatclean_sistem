<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['submit']);

const NAME_MAX_LENGTH = 100;

const { t } = useI18n();

const dialogRef = ref(null);
const pipelineId = ref(null);
const name = ref('');

const isEditing = computed(() => Boolean(pipelineId.value));
const trimmedName = computed(() => name.value.trim());
const nameError = computed(() =>
  trimmedName.value.length > NAME_MAX_LENGTH
    ? t('CRM_PIPELINES.FORM.NAME.TOO_LONG', { max: NAME_MAX_LENGTH })
    : ''
);

const open = (pipeline = null) => {
  pipelineId.value = pipeline?.id ?? null;
  name.value = pipeline?.name ?? '';
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const onConfirm = () => {
  if (props.isLoading || !trimmedName.value || nameError.value) return;
  emit('submit', { id: pipelineId.value, name: trimmedName.value });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('CRM_PIPELINES.FORM.EDIT_TITLE')
        : t('CRM_PIPELINES.FORM.CREATE_TITLE')
    "
    :description="isEditing ? '' : t('CRM_PIPELINES.FORM.CREATE_DESCRIPTION')"
    :confirm-button-label="
      isEditing ? t('CRM_PIPELINES.FORM.SAVE') : t('CRM_PIPELINES.FORM.CREATE')
    "
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="!trimmedName || Boolean(nameError)"
    :is-loading="props.isLoading"
    @confirm="onConfirm"
  >
    <Input
      v-model="name"
      :label="t('CRM_PIPELINES.FORM.NAME.LABEL')"
      :placeholder="t('CRM_PIPELINES.FORM.NAME.PLACEHOLDER')"
      :message="nameError"
      :message-type="nameError ? 'error' : 'info'"
      autofocus
    />
  </Dialog>
</template>
