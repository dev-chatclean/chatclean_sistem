<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import { useAlert } from 'dashboard/composables';
import { useCrmSettingsStore } from 'dashboard/stores/crmSettings';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PipelineDialog from './PipelineDialog.vue';
import StageDialog from './StageDialog.vue';

const { t } = useI18n();
const crm = useCrmSettingsStore();

const selectedId = ref(null);
const pipelineDialogRef = ref(null);
const stageDialogRef = ref(null);
const confirmDialogRef = ref(null);
const dialogError = ref('');
const isSaving = ref(false);
// Exclusão aguardando confirmação: { title, description, action }.
const pendingDelete = ref(null);

const selectedPipeline = computed(
  () =>
    crm.pipelines.find(pipeline => pipeline.id === selectedId.value) ||
    crm.defaultPipeline ||
    crm.pipelines[0]
);

const closingStages = computed(() =>
  (selectedPipeline.value?.stages || []).filter(
    stage => stage.status !== 'open'
  )
);

// Só os estágios abertos se movem; Ganho e Perdido ficam fixos no fim (CA 9.4).
const openStages = computed({
  get: () =>
    (selectedPipeline.value?.stages || []).filter(
      stage => stage.status === 'open'
    ),
  set: stages =>
    crm
      .reorderStages(
        selectedPipeline.value.id,
        stages.map(stage => stage.id)
      )
      .catch(error => useAlert(error.message)),
});

const save = async (dialogRef, action, successMessage) => {
  dialogError.value = '';
  isSaving.value = true;
  try {
    await action();
    dialogRef.value?.close();
    useAlert(successMessage);
  } catch (error) {
    dialogError.value = error.message;
  } finally {
    isSaving.value = false;
  }
};

const openCreate = () => {
  dialogError.value = '';
  pipelineDialogRef.value?.open();
};

const openEditPipeline = () => {
  dialogError.value = '';
  pipelineDialogRef.value?.open(selectedPipeline.value);
};

const onPipelineSubmit = ({ id, attributes }) =>
  save(
    pipelineDialogRef,
    async () => {
      if (id) {
        await crm.updatePipeline(id, attributes);
      } else {
        selectedId.value = (await crm.createPipeline(attributes)).id;
      }
    },
    t('CRM.SETTINGS.PIPELINES.SAVED')
  );

const openStageDialog = (stage = null) => {
  dialogError.value = '';
  stageDialogRef.value?.open(stage);
};

const onStageSubmit = ({ id, attributes }) => {
  const pipelineId = selectedPipeline.value.id;
  return save(
    stageDialogRef,
    () =>
      id
        ? crm.updateStage(pipelineId, id, attributes)
        : crm.createStage(pipelineId, attributes),
    t('CRM.SETTINGS.STAGES.SAVED')
  );
};

const confirmDelete = ({ title, description, action }) => {
  pendingDelete.value = { title, description, action };
  confirmDialogRef.value?.open();
};

const askDeletePipeline = () => {
  const pipeline = selectedPipeline.value;
  confirmDelete({
    title: t('CRM.SETTINGS.PIPELINES.DELETE.TITLE'),
    description: t('CRM.SETTINGS.PIPELINES.DELETE.DESCRIPTION', {
      name: pipeline.name,
    }),
    action: async () => {
      await crm.deletePipeline(pipeline.id);
      selectedId.value = null;
    },
  });
};

const askDeleteStage = stage => {
  const pipelineId = selectedPipeline.value.id;
  confirmDelete({
    title: t('CRM.SETTINGS.STAGES.DELETE.TITLE'),
    description: t('CRM.SETTINGS.STAGES.DELETE.DESCRIPTION', {
      name: stage.name,
    }),
    action: () => crm.deleteStage(pipelineId, stage.id),
  });
};

// Com deals vinculados a API recusa (422): o modal fecha e o toast explica (FA 9.1).
const onConfirmDelete = async () => {
  const { action } = pendingDelete.value;
  confirmDialogRef.value?.close();
  try {
    await action();
    useAlert(t('CRM.SETTINGS.DELETED'));
  } catch (error) {
    useAlert(error.message);
  }
};

onMounted(() => crm.fetchPipelines().catch(error => useAlert(error.message)));

defineExpose({ openCreate });
</script>

<template>
  <div>
    <div
      v-if="crm.uiFlags.isFetchingPipelines && !crm.pipelines.length"
      class="flex justify-center py-10"
    >
      <Spinner />
    </div>

    <p
      v-else-if="!crm.pipelines.length"
      class="py-16 text-sm text-center text-n-slate-11"
      data-test="no-pipelines"
    >
      {{ t('CRM.SETTINGS.PIPELINES.EMPTY') }}
    </p>

    <div v-else class="flex flex-col gap-6 md:flex-row">
      <nav class="flex flex-col gap-1 md:w-56 shrink-0">
        <button
          v-for="pipeline in crm.pipelines"
          :key="pipeline.id"
          type="button"
          class="flex items-center justify-between gap-2 px-3 py-2 text-sm text-start rounded-lg"
          :class="
            pipeline.id === selectedPipeline?.id
              ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
              : 'text-n-slate-11 hover:bg-n-alpha-1'
          "
          data-test="pipeline-item"
          @click="selectedId = pipeline.id"
        >
          <span class="truncate">{{ pipeline.name }}</span>
          <span
            v-if="pipeline.isDefault"
            class="px-1.5 text-xs rounded-md shrink-0 bg-n-blue-3 text-n-blue-11"
            data-test="default-tag"
          >
            {{ t('CRM.SETTINGS.PIPELINES.DEFAULT_TAG') }}
          </span>
        </button>
      </nav>

      <section
        v-if="selectedPipeline"
        class="flex flex-col flex-1 min-w-0 gap-4"
      >
        <header class="flex flex-wrap items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ selectedPipeline.name }}
            </h3>
            <p
              v-if="selectedPipeline.description"
              class="text-sm text-n-slate-11"
            >
              {{ selectedPipeline.description }}
            </p>
          </div>
          <div class="flex gap-2">
            <Button
              :label="t('CRM.SETTINGS.PIPELINES.EDIT')"
              icon="i-lucide-pencil"
              size="sm"
              variant="faded"
              color="slate"
              data-test="edit-pipeline"
              @click="openEditPipeline"
            />
            <Button
              :label="t('CRM.SETTINGS.PIPELINES.DELETE.ACTION')"
              icon="i-lucide-trash-2"
              size="sm"
              variant="faded"
              color="ruby"
              data-test="delete-pipeline"
              @click="askDeletePipeline"
            />
          </div>
        </header>

        <div class="flex items-center justify-between">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.STAGES.TITLE') }}
          </h4>
          <Button
            :label="t('CRM.SETTINGS.STAGES.NEW')"
            icon="i-lucide-plus"
            size="xs"
            variant="faded"
            data-test="new-stage"
            @click="openStageDialog()"
          />
        </div>

        <div class="flex flex-col gap-2">
          <Draggable
            v-model="openStages"
            item-key="id"
            handle=".stage-handle"
            class="flex flex-col gap-2"
          >
            <template #item="{ element }">
              <div
                class="flex items-center gap-3 px-3 py-2 rounded-lg outline outline-1 outline-n-weak bg-n-solid-1"
                data-test="open-stage"
              >
                <Icon
                  icon="i-lucide-grip-vertical"
                  class="stage-handle size-4 shrink-0 cursor-grab text-n-slate-10"
                  :title="t('CRM.SETTINGS.STAGES.DRAG')"
                />
                <span class="flex-1 text-sm truncate text-n-slate-12">
                  {{ element.name }}
                </span>
                <span class="text-xs tabular-nums text-n-slate-11">
                  {{
                    t('CRM.SETTINGS.STAGES.PROBABILITY', {
                      probability: element.probability,
                    })
                  }}
                </span>
                <Button
                  icon="i-lucide-pencil"
                  size="xs"
                  variant="ghost"
                  color="slate"
                  :title="t('CRM.SETTINGS.STAGES.EDIT')"
                  @click="openStageDialog(element)"
                />
                <Button
                  icon="i-lucide-trash-2"
                  size="xs"
                  variant="ghost"
                  color="ruby"
                  :title="t('CRM.SETTINGS.STAGES.DELETE.ACTION')"
                  data-test="delete-stage"
                  @click="askDeleteStage(element)"
                />
              </div>
            </template>
          </Draggable>

          <div
            v-for="stage in closingStages"
            :key="stage.id"
            class="flex items-center gap-3 px-3 py-2 rounded-lg outline outline-1 outline-n-weak bg-n-alpha-1"
            data-test="closing-stage"
          >
            <Icon
              icon="i-lucide-lock"
              class="size-4 shrink-0 text-n-slate-10"
            />
            <span class="flex-1 text-sm truncate text-n-slate-12">
              {{ stage.name }}
            </span>
            <span
              class="px-2 py-0.5 text-xs font-medium rounded bg-n-slate-3 text-n-slate-11"
            >
              {{ t('CRM.SETTINGS.STAGES.CLOSING_TAG') }}
            </span>
            <span class="text-xs tabular-nums text-n-slate-11">
              {{
                t('CRM.SETTINGS.STAGES.PROBABILITY', {
                  probability: stage.probability,
                })
              }}
            </span>
            <Button
              icon="i-lucide-pencil"
              size="xs"
              variant="ghost"
              color="slate"
              :title="t('CRM.SETTINGS.STAGES.RENAME')"
              @click="openStageDialog(stage)"
            />
          </div>
        </div>
      </section>
    </div>

    <PipelineDialog
      ref="pipelineDialogRef"
      :default-pipeline="crm.defaultPipeline"
      :is-loading="isSaving"
      :error-message="dialogError"
      @submit="onPipelineSubmit"
    />
    <StageDialog
      ref="stageDialogRef"
      :is-loading="isSaving"
      :error-message="dialogError"
      @submit="onStageSubmit"
    />
    <Dialog
      ref="confirmDialogRef"
      type="alert"
      :title="pendingDelete?.title"
      :description="pendingDelete?.description"
      :confirm-button-label="t('CRM.SETTINGS.CONFIRM_DELETE')"
      :cancel-button-label="t('CRM.SETTINGS.CANCEL')"
      @confirm="onConfirmDelete"
    />
  </div>
</template>
