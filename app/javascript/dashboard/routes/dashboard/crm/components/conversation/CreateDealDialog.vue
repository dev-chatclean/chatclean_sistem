<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const props = defineProps({
  pipelines: { type: Array, default: () => [] },
  defaultPipelineId: { type: Number, default: null },
  agents: { type: Array, default: () => [] },
  currentUserId: { type: Number, default: null },
  isLoading: { type: Boolean, default: false },
  errorMessage: { type: String, default: '' },
});

const emit = defineEmits(['create']);

const { t } = useI18n();
const dialogRef = ref(null);

const form = reactive({
  title: '',
  value: 0,
  pipelineId: null,
  stageId: null,
  expectedCloseDate: '',
  assigneeId: '',
});

const pipelineOptions = computed(() =>
  props.pipelines.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  }))
);

const selectedPipeline = computed(() =>
  props.pipelines.find(pipeline => pipeline.id === form.pipelineId)
);

const stageOptions = computed(() =>
  (selectedPipeline.value?.stages || []).map(stage => ({
    value: stage.id,
    label: stage.name,
  }))
);

const assigneeOptions = computed(() => [
  { value: '', label: t('CRM.CONVERSATION_PANEL.CREATE.NO_ASSIGNEE') },
  ...props.agents.map(agent => ({ value: agent.id, label: agent.name })),
]);

// Os estágios vêm ordenados por position; o primeiro aberto é o início do funil (FA 8.4).
const firstOpenStageId = pipeline =>
  pipeline?.stages.find(stage => stage.status === 'open')?.id || null;

watch(
  () => form.pipelineId,
  () => {
    form.stageId = firstOpenStageId(selectedPipeline.value);
  }
);

const canSubmit = computed(() => form.title.trim() && form.stageId);

const open = () => {
  Object.assign(form, {
    title: '',
    value: 0,
    pipelineId: props.defaultPipelineId,
    stageId: firstOpenStageId(
      props.pipelines.find(pipeline => pipeline.id === props.defaultPipelineId)
    ),
    expectedCloseDate: '',
    assigneeId: props.currentUserId || '',
  });
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!canSubmit.value) return;
  emit('create', {
    title: form.title.trim(),
    value: Number(form.value) || 0,
    crm_stage_id: Number(form.stageId),
    expected_close_date: form.expectedCloseDate || null,
    assignee_id: form.assigneeId ? Number(form.assigneeId) : null,
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CRM.CONVERSATION_PANEL.CREATE.TITLE')"
    :confirm-button-label="t('CRM.CONVERSATION_PANEL.CREATE.CONFIRM')"
    :cancel-button-label="t('CRM.CONVERSATION_PANEL.CREATE.CANCEL')"
    :disable-confirm-button="!canSubmit"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.title"
        :label="t('CRM.CONVERSATION_PANEL.CREATE.TITLE_LABEL')"
        :placeholder="t('CRM.CONVERSATION_PANEL.CREATE.TITLE_PLACEHOLDER')"
        data-test="deal-title"
      />
      <Input
        v-model="form.value"
        type="number"
        step="0.01"
        :label="t('CRM.CONVERSATION_PANEL.CREATE.VALUE_LABEL')"
        data-test="deal-value"
      />
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CRM.CONVERSATION_PANEL.CREATE.PIPELINE_LABEL') }}
        <Select
          v-model="form.pipelineId"
          :options="pipelineOptions"
          data-test="deal-pipeline"
        />
      </label>
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CRM.CONVERSATION_PANEL.CREATE.STAGE_LABEL') }}
        <Select
          v-model="form.stageId"
          :options="stageOptions"
          data-test="deal-stage"
        />
      </label>
      <Input
        v-model="form.expectedCloseDate"
        type="date"
        :label="t('CRM.CONVERSATION_PANEL.CREATE.CLOSE_DATE_LABEL')"
        data-test="deal-close-date"
      />
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CRM.CONVERSATION_PANEL.CREATE.ASSIGNEE_LABEL') }}
        <Select
          v-model="form.assigneeId"
          :options="assigneeOptions"
          data-test="deal-assignee"
        />
      </label>
      <p v-if="errorMessage" class="text-sm text-n-ruby-11" role="alert">
        {{ errorMessage }}
      </p>
    </div>
  </Dialog>
</template>
