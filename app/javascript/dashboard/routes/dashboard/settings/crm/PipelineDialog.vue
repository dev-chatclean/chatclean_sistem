<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  defaultPipeline: { type: Object, default: null },
  isLoading: { type: Boolean, default: false },
  errorMessage: { type: String, default: '' },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const dialogRef = ref(null);
// Funil em edição; null ao criar.
const pipeline = ref(null);
const form = reactive({ name: '', description: '', isDefault: false });

// Avisa qual funil deixa de ser o padrão ao ligar o switch (CA 9.3).
const replacedDefault = computed(() =>
  form.isDefault &&
  props.defaultPipeline &&
  props.defaultPipeline.id !== pipeline.value?.id
    ? props.defaultPipeline
    : null
);

const open = (record = null) => {
  pipeline.value = record;
  Object.assign(form, {
    name: record?.name || '',
    description: record?.description || '',
    isDefault: record?.isDefault || false,
  });
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!form.name.trim()) return;
  emit('submit', {
    id: pipeline.value?.id,
    attributes: {
      name: form.name.trim(),
      description: form.description.trim() || null,
      is_default: form.isDefault,
    },
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      pipeline
        ? t('CRM.SETTINGS.PIPELINES.DIALOG.EDIT_TITLE')
        : t('CRM.SETTINGS.PIPELINES.DIALOG.CREATE_TITLE')
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
        :label="t('CRM.SETTINGS.PIPELINES.DIALOG.NAME')"
        :message="errorMessage"
        :message-type="errorMessage ? 'error' : 'info'"
        data-test="pipeline-name"
      />
      <TextArea
        v-model="form.description"
        :label="t('CRM.SETTINGS.PIPELINES.DIALOG.DESCRIPTION')"
        :max-length="500"
        data-test="pipeline-description"
      />
      <label class="flex items-center gap-2 text-sm text-n-slate-12">
        <Switch v-model="form.isDefault" data-test="pipeline-default" />
        {{ t('CRM.SETTINGS.PIPELINES.DIALOG.DEFAULT') }}
      </label>
      <p
        v-if="replacedDefault"
        class="text-sm text-n-amber-11"
        data-test="default-warning"
      >
        {{
          t('CRM.SETTINGS.PIPELINES.DIALOG.DEFAULT_WARNING', {
            name: replacedDefault.name,
          })
        }}
      </p>
    </div>
  </Dialog>
</template>
