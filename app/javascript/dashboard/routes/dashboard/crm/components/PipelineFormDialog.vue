<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import StageColorPicker from './StageColorPicker.vue';
import {
  DEFAULT_LOST_COLOR,
  DEFAULT_WON_COLOR,
  PIPELINE_NAME_MAX_LENGTH,
  STAGE_NAME_MAX_LENGTH,
  STAGE_NAME_MIN_LENGTH,
} from '../constants';

const props = defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const dialogRef = ref(null);
const pipelineId = ref(null);
const name = ref('');
const wonStage = reactive({ name: '', color: DEFAULT_WON_COLOR });
const lostStage = reactive({ name: '', color: DEFAULT_LOST_COLOR });

const isEditing = computed(() => Boolean(pipelineId.value));

const nameError = computed(() =>
  name.value.trim().length > PIPELINE_NAME_MAX_LENGTH
    ? t('CRM_PIPELINES.FORM.NAME.TOO_LONG', { max: PIPELINE_NAME_MAX_LENGTH })
    : ''
);

const stageNameError = stageName => {
  const length = stageName.trim().length;
  if (length >= STAGE_NAME_MIN_LENGTH && length <= STAGE_NAME_MAX_LENGTH) {
    return '';
  }
  return t('CRM_PIPELINES.FORM.STAGE_NAME_LENGTH', {
    min: STAGE_NAME_MIN_LENGTH,
    max: STAGE_NAME_MAX_LENGTH,
  });
};

const wonNameError = computed(() => stageNameError(wonStage.name));
const lostNameError = computed(() => stageNameError(lostStage.name));

const isInvalid = computed(() => {
  if (!name.value.trim() || nameError.value) return true;
  if (isEditing.value) return false;
  return Boolean(wonNameError.value || lostNameError.value);
});

const open = (pipeline = null) => {
  pipelineId.value = pipeline?.id ?? null;
  name.value = pipeline?.name ?? '';
  Object.assign(wonStage, {
    name: t('CRM_PIPELINES.FORM.WON.DEFAULT_NAME'),
    color: DEFAULT_WON_COLOR,
  });
  Object.assign(lostStage, {
    name: t('CRM_PIPELINES.FORM.LOST.DEFAULT_NAME'),
    color: DEFAULT_LOST_COLOR,
  });
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const onConfirm = () => {
  if (props.isLoading || isInvalid.value) return;

  const payload = { name: name.value.trim() };
  if (!isEditing.value) {
    payload.won_stage = { ...wonStage, name: wonStage.name.trim() };
    payload.lost_stage = { ...lostStage, name: lostStage.name.trim() };
  }
  emit('submit', { id: pipelineId.value, payload });
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
    :confirm-button-label="
      isEditing ? t('CRM_PIPELINES.FORM.SAVE') : t('CRM_PIPELINES.FORM.CREATE')
    "
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="isInvalid"
    :is-loading="props.isLoading"
    overflow-y-auto
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-5">
      <Input
        v-model="name"
        :label="t('CRM_PIPELINES.FORM.NAME.LABEL')"
        :placeholder="t('CRM_PIPELINES.FORM.NAME.PLACEHOLDER')"
        :message="nameError"
        :message-type="nameError ? 'error' : 'info'"
        autofocus
      />

      <template v-if="!isEditing">
        <div class="flex flex-col gap-3">
          <span class="text-heading-3 text-n-slate-12">
            {{ t('CRM_PIPELINES.FORM.CLOSING_STAGES') }}
          </span>
          <div
            v-for="stage in [
              { key: 'WON', model: wonStage, error: wonNameError },
              { key: 'LOST', model: lostStage, error: lostNameError },
            ]"
            :key="stage.key"
            class="flex flex-col gap-3 p-3 border rounded-xl border-n-weak"
          >
            <Input
              v-model="stage.model.name"
              :label="t(`CRM_PIPELINES.FORM.${stage.key}.LABEL`)"
              :message="stage.error"
              :message-type="stage.error ? 'error' : 'info'"
            />
            <StageColorPicker v-model="stage.model.color" />
          </div>
          <span class="text-body-main text-n-slate-11">
            {{ t('CRM_PIPELINES.FORM.CLOSING_STAGES_HINT') }}
          </span>
        </div>
      </template>
    </div>
  </Dialog>
</template>
