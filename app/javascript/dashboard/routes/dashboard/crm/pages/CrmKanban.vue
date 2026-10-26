<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useCrmKanbanStore } from 'dashboard/stores/crmKanban';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanColumn from '../components/KanbanColumn.vue';
import LossReasonModal from '../components/LossReasonModal.vue';

const { t } = useI18n();
const store = useStore();
const kanban = useCrmKanbanStore();
const { isAdmin } = useAdmin();
const agents = useMapGetter('agents/getVerifiedAgents');
const currentUserId = useMapGetter('getCurrentUserID');

const lossModalRef = ref(null);
// Deal solto em "Perdido" que espera o motivo para ir à API.
const pendingLoss = ref(null);
const isSavingLoss = ref(false);
let dragOrigin = null;

// As actions da store lançam o erro já traduzido pela API; aqui ele vira alerta.
const runSafely = async action => {
  try {
    await action();
  } catch (error) {
    useAlert(error.message || t('CRM.KANBAN.MESSAGES.LOAD_ERROR'));
  }
};

const pipelineOptions = computed(() =>
  kanban.pipelines.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  }))
);

const assigneeOptions = computed(() => [
  { value: '', label: t('CRM.KANBAN.ASSIGNEE_FILTER.ALL') },
  { value: currentUserId.value, label: t('CRM.KANBAN.ASSIGNEE_FILTER.MINE') },
  { value: 'none', label: t('CRM.KANBAN.ASSIGNEE_FILTER.NONE') },
  ...agents.value
    .filter(agent => agent.id !== currentUserId.value)
    .map(agent => ({ value: agent.id, label: agent.name })),
]);

const selectedPipelineId = computed({
  get: () => kanban.selectedPipelineId,
  set: value => runSafely(() => kanban.selectPipeline(Number(value))),
});

const assigneeFilter = computed({
  get: () => kanban.assigneeFilter,
  set: value => runSafely(() => kanban.setAssigneeFilter(value)),
});

// Só os estágios abertos são reordenáveis; Ganho e Perdido ficam fixos no fim.
const openStages = computed({
  get: () => kanban.openStages,
  set: stages =>
    runSafely(() => kanban.reorderStages(stages.map(stage => stage.id))),
});

const emptyColumn = { deals: [], hasMore: false, isLoading: false };
const columnFor = stage => kanban.columns[stage.id] || emptyColumn;

const loadBoard = () =>
  runSafely(async () => {
    await kanban.fetchPipelines();
    if (kanban.selectedPipelineId) await kanban.loadBoard();
  });

const onDragStart = origin => {
  dragOrigin = origin;
};

const onDealAdded = ({ deal, stage }) => {
  const move = { deal, toStageId: stage.id, origin: dragOrigin };
  if (stage.status === 'lost') {
    pendingLoss.value = move;
    lossModalRef.value?.open();
    return;
  }
  runSafely(() => kanban.moveDeal(move));
};

const onLossConfirm = async ({ lossReasonId, lossDetails }) => {
  isSavingLoss.value = true;
  await runSafely(() =>
    kanban.moveDeal({ ...pendingLoss.value, lossReasonId, lossDetails })
  );
  isSavingLoss.value = false;
  pendingLoss.value = null;
  lossModalRef.value?.close();
};

const onLossCancel = () => {
  if (pendingLoss.value) kanban.revertMove(pendingLoss.value);
  pendingLoss.value = null;
};

const onAssign = (deal, assigneeId) =>
  runSafely(() => kanban.assignDeal(deal, assigneeId));

// Ao voltar para a aba, o quadro recarrega para refletir mudanças de outros agentes.
const onVisibilityChange = () => {
  if (document.visibilityState === 'visible' && !pendingLoss.value) loadBoard();
};

onMounted(() => {
  store.dispatch('agents/get');
  loadBoard();
  runSafely(() => kanban.fetchLossReasons());
  document.addEventListener('visibilitychange', onVisibilityChange);
});

onBeforeUnmount(() =>
  document.removeEventListener('visibilitychange', onVisibilityChange)
);
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
    <header
      class="flex flex-wrap items-center gap-3 px-6 py-4 border-b border-n-weak"
    >
      <h1 class="mr-auto text-xl font-medium text-n-slate-12">
        {{ t('CRM.KANBAN.HEADER') }}
      </h1>
      <template v-if="kanban.pipelines.length">
        <Select
          v-model="selectedPipelineId"
          :options="pipelineOptions"
          :aria-label="t('CRM.KANBAN.PIPELINE_LABEL')"
          data-test="pipeline-select"
        />
        <Select
          v-if="isAdmin"
          v-model="assigneeFilter"
          :options="assigneeOptions"
          :aria-label="t('CRM.KANBAN.ASSIGNEE_FILTER.LABEL')"
          data-test="assignee-filter"
        />
      </template>
    </header>

    <div
      v-if="kanban.uiFlags.isFetchingPipelines && !kanban.pipelines.length"
      class="flex justify-center flex-1 py-10"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!kanban.pipelines.length"
      class="flex flex-col items-center justify-center flex-1 gap-2 px-6 text-center"
      data-test="empty-state"
    >
      <Icon icon="i-lucide-square-kanban" class="size-10 text-n-slate-9" />
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('CRM.KANBAN.EMPTY_STATE.TITLE') }}
      </h2>
      <p class="max-w-md text-sm text-n-slate-11">
        {{ t('CRM.KANBAN.EMPTY_STATE.DESCRIPTION') }}
      </p>
      <RouterLink
        v-if="isAdmin"
        :to="{ name: 'crm_settings_index' }"
        class="text-sm text-n-blue-11 hover:underline"
        data-test="settings-link"
      >
        {{ t('CRM.KANBAN.EMPTY_STATE.SETTINGS_LINK') }}
      </RouterLink>
    </div>

    <div v-else class="flex flex-1 min-h-0 gap-3 p-4 overflow-x-auto">
      <Draggable
        v-model="openStages"
        item-key="id"
        handle=".stage-handle"
        :disabled="!isAdmin"
        class="flex gap-3"
      >
        <template #item="{ element }">
          <KanbanColumn
            :stage="element"
            :column="columnFor(element)"
            :summary="kanban.summary[element.id]"
            :agents="agents"
            :can-reorder="isAdmin"
            @drag-start="onDragStart"
            @deal-added="onDealAdded"
            @load-more="kanban.fetchColumn(element.id)"
            @assign="onAssign"
          />
        </template>
      </Draggable>
      <KanbanColumn
        v-for="stage in kanban.closingStages"
        :key="stage.id"
        :stage="stage"
        :column="columnFor(stage)"
        :summary="kanban.summary[stage.id]"
        :agents="agents"
        @drag-start="onDragStart"
        @deal-added="onDealAdded"
        @load-more="kanban.fetchColumn(stage.id)"
        @assign="onAssign"
      />
    </div>

    <LossReasonModal
      ref="lossModalRef"
      :deal-title="pendingLoss?.deal.title"
      :loss-reasons="kanban.lossReasons"
      :is-loading="isSavingLoss"
      @confirm="onLossConfirm"
      @cancel="onLossCancel"
    />
  </div>
</template>
