<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useStore } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmSettingsAPI from 'dashboard/api/crm/settings';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PipelineSettingsDialog from '../components/PipelineSettingsDialog.vue';
import AiSettingsDialog from '../components/AiSettingsDialog.vue';
import StageDialog from '../components/StageDialog.vue';
import ImpulsesDialog from '../components/ImpulsesDialog.vue';
import Draggable from 'vuedraggable';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import DealCard from '../components/deals/DealCard.vue';
import DealFormDialog from '../components/deals/DealFormDialog.vue';
import DealDetailDialog from '../components/deals/DealDetailDialog.vue';
import CloseDealDialog from '../components/deals/CloseDealDialog.vue';
import MoveDealDialog from '../components/deals/MoveDealDialog.vue';
import BoardToolbar from '../components/board/BoardToolbar.vue';
import { formatCurrency, isClosingStage } from '../dealHelpers';
import { applyBoardFilters, defaultBoardState } from '../useBoardFilters';
import { SERVER_CLOSED_WINDOW_DAYS } from '../constants';
import { useItemLabel } from '../useItemLabel';
import {
  CLOSING_STAGE_TYPES,
  DAY_IN_SECONDS,
  UI_SETTINGS_KEYS,
} from '../constants';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const { uiSettings, updateUISettings } = useUISettings();
const store = useStore();
const { itemLabel } = useItemLabel();

const pipelines = ref([]);
const isFetching = ref(true);
const isSaving = ref(false);
const searchQuery = ref('');
const openPipelineMenuId = ref(null);
const isSettingsMenuOpen = ref(false);
const pipelineToDelete = ref(null);
const autoCreateDeals = ref(true);
const leadAlertDays = ref(null);
const settingsDialogRef = ref(null);
const deleteDialogRef = ref(null);
const aiDialogRef = ref(null);
const stageDialogRef = ref(null);
const impulsesDialogRef = ref(null);
const stageDeleteDialogRef = ref(null);
const openStageMenuId = ref(null);
const stageToDelete = ref(null);
const deals = ref([]);
const boardState = ref(defaultBoardState());
const columns = ref({});
const isMovingDeal = ref(false);
const dealToDelete = ref(null);
const stageTransferTarget = ref(null);
const dealFormRef = ref(null);
const dealDetailRef = ref(null);
const closeDialogRef = ref(null);
const moveDialogRef = ref(null);
const dealDeleteDialogRef = ref(null);

const isPanelCollapsed = computed(
  () => uiSettings.value[UI_SETTINGS_KEYS.PANEL_COLLAPSED] === true
);
const showLeadEntryHint = computed(
  () =>
    isAdmin.value &&
    !autoCreateDeals.value &&
    uiSettings.value[UI_SETTINGS_KEYS.LEAD_ENTRY_HINT_DISMISSED] !== true
);

const togglePanel = () =>
  updateUISettings({
    [UI_SETTINGS_KEYS.PANEL_COLLAPSED]: !isPanelCollapsed.value,
  });

const dismissLeadEntryHint = () =>
  updateUISettings({ [UI_SETTINGS_KEYS.LEAD_ENTRY_HINT_DISMISSED]: true });

const filteredPipelines = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return pipelines.value;
  return pipelines.value.filter(pipeline =>
    pipeline.name.toLowerCase().includes(query)
  );
});

const groupedPipelines = computed(() => {
  const groups = new Map();
  filteredPipelines.value.forEach(pipeline => {
    const group = pipeline.group_name || '';
    if (!groups.has(group)) groups.set(group, []);
    groups.get(group).push(pipeline);
  });
  return [...groups.entries()]
    .sort(([a], [b]) => {
      if (a === '') return -1;
      if (b === '') return 1;
      return a.localeCompare(b);
    })
    .map(([name, items]) => ({ name, items }));
});

const hasDefaultPipeline = computed(() =>
  pipelines.value.some(pipeline => pipeline.is_default)
);

const selectedPipeline = computed(() => {
  const id = Number(route.params.pipelineId);
  return (
    pipelines.value.find(pipeline => pipeline.id === id) ||
    pipelines.value.find(pipeline => pipeline.is_default) ||
    pipelines.value[0]
  );
});

const settingsActions = () => [
  {
    label: t('CRM_PIPELINES.MENU.EDIT'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('CRM_PIPELINES.MENU.CARD'),
    value: 'card',
    action: 'card',
    icon: 'i-lucide-credit-card',
  },
  {
    label: t('CRM_PIPELINES.MENU.LEAD_ENTRY'),
    value: 'lead_entry',
    action: 'lead_entry',
    icon: 'i-lucide-funnel',
  },
  {
    label: t('CRM_PIPELINES.MENU.AI'),
    value: 'ai',
    action: 'ai',
    icon: 'i-lucide-lightbulb',
  },
];

const pipelineMenuItems = pipeline => [
  ...settingsActions(),
  ...(pipeline.is_default
    ? []
    : [
        {
          label: t('CRM_PIPELINES.MENU.SET_DEFAULT'),
          value: 'set_default',
          action: 'set_default',
          icon: 'i-lucide-star',
        },
      ]),
  {
    label: pipeline.is_default
      ? t('CRM_PIPELINES.MENU.DELETE_DEFAULT_BLOCKED')
      : t('CRM_PIPELINES.MENU.DELETE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash-2',
    disabled: pipeline.is_default,
  },
];

const settingsMenuItems = computed(() => settingsActions());

const emptyStageMessage = stage => {
  const item = itemLabel(selectedPipeline.value, 2).toLowerCase();
  if (!isClosingStage(stage)) {
    return t('CRM_PIPELINES.BOARD.EMPTY_STAGE', {
      item: itemLabel(selectedPipeline.value, 1).toLowerCase(),
    });
  }
  const period =
    boardState.value.view === 'all'
      ? ''
      : t('CRM_DEALS.BOARD.PERIOD_PHRASE', {
          n: boardState.value.closedPeriod,
        });
  const key =
    stage.stage_type === 'won'
      ? 'CRM_PIPELINES.BOARD.EMPTY_WON'
      : 'CRM_PIPELINES.BOARD.EMPTY_LOST';
  return t(key, { item, period }).replace(/\s+/g, ' ');
};

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const showValue = computed(
  () => selectedPipeline.value?.pipeline_type !== 'management'
);
const visibleDeals = computed(() =>
  applyBoardFilters(
    deals.value,
    boardState.value,
    selectedPipeline.value?.stages || []
  )
);
const openDeals = computed(() =>
  visibleDeals.value.filter(deal => deal.status === 'open')
);
const openDealsCount = computed(() => openDeals.value.length);
const openDealsTotal = computed(() =>
  openDeals.value.reduce((sum, deal) => sum + deal.value, 0)
);
const headerSummary = computed(() => {
  const count = t('CRM_DEALS.BOARD.SUMMARY', {
    count: openDealsCount.value,
    item: itemLabel(selectedPipeline.value, openDealsCount.value).toLowerCase(),
  });
  const value =
    showValue.value && openDealsCount.value
      ? formatCurrency(openDealsTotal.value)
      : t('CRM_DEALS.BOARD.NO_DATA');
  return t('CRM_DEALS.BOARD.SUMMARY_WITH_VALUE', { summary: count, value });
});
const stageTotal = stage =>
  (columns.value[stage.id] || []).reduce((sum, deal) => sum + deal.value, 0);
const stageSummary = stage => {
  const count = (columns.value[stage.id] || []).length;
  const value =
    showValue.value && count
      ? formatCurrency(stageTotal(stage))
      : t('CRM_DEALS.BOARD.NO_DATA');
  return t('CRM_DEALS.BOARD.STAGE_SUMMARY', { value, count });
};
// Leads from the lead entry land in the default pipeline's first column.
const waitingLeadsCount = computed(() => {
  if (!autoCreateDeals.value || !leadAlertDays.value) return 0;
  if (!selectedPipeline.value?.is_default) return 0;
  const limit = Date.now() / 1000 - leadAlertDays.value * DAY_IN_SECONDS;
  const initialStage = selectedPipeline.value.stages.find(
    stage => stage.stage_type === 'initial'
  );
  return deals.value.filter(
    deal =>
      deal.status === 'open' &&
      deal.stage_id === initialStage?.id &&
      deal.stage_entered_at < limit
  ).length;
});
const waitingLeadsLabel = computed(() =>
  t(
    'CRM_DEALS.BOARD.WAITING_LEADS',
    { count: waitingLeadsCount.value, days: leadAlertDays.value },
    waitingLeadsCount.value
  )
);
const closedWindowLabel = computed(() =>
  boardState.value.view === 'all'
    ? t('CRM_DEALS.TOOLBAR.VIEW.ALL')
    : t('CRM_DEALS.BOARD.LAST_DAYS', { n: boardState.value.closedPeriod })
);
const needsAllDeals = computed(
  () =>
    boardState.value.view === 'all' ||
    boardState.value.closedPeriod > SERVER_CLOSED_WINDOW_DAYS
);

const rebuildColumns = () => {
  const grouped = {};
  (selectedPipeline.value?.stages || []).forEach(stage => {
    grouped[stage.id] = [];
  });
  visibleDeals.value.forEach(deal => {
    if (grouped[deal.stage_id]) grouped[deal.stage_id].push(deal);
  });
  columns.value = grouped;
};

const fetchDeals = async () => {
  if (!selectedPipeline.value) return;
  try {
    const { data } = await CrmDealsAPI.list(
      selectedPipeline.value.id,
      needsAllDeals.value ? 'all' : 'open'
    );
    deals.value = data.payload;
    selectedPipeline.value.open_deals_count = data.payload.filter(
      deal => deal.status === 'open'
    ).length;
  } catch (error) {
    deals.value = [];
    useAlert(t('CRM_DEALS.API.FETCH_ERROR'));
  } finally {
    rebuildColumns();
  }
};

const moveDeal = async (deal, changes) => {
  isMovingDeal.value = true;
  try {
    await CrmDealsAPI.update(deal.id, { deal: changes });
    return true;
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
    return false;
  } finally {
    isMovingDeal.value = false;
    await fetchDeals();
    dealDetailRef.value?.reload();
  }
};

const onColumnChange = (stage, event) => {
  if (!event.added) return;
  const deal = event.added.element;
  if (isClosingStage(stage)) {
    closeDialogRef.value?.open({ deal, stage });
    return;
  }
  moveDeal(deal, { stage_id: stage.id });
};

const confirmCloseDeal = async ({ deal, stage, ...reason }) => {
  const moved = await moveDeal(deal, { stage_id: stage.id, ...reason });
  if (moved) closeDialogRef.value?.close();
};

const onMoveDialog = ({ deal, stageId }) => {
  const stage = selectedPipeline.value.stages.find(item => item.id === stageId);
  moveDialogRef.value?.close();
  if (isClosingStage(stage)) {
    closeDialogRef.value?.open({ deal, stage });
    return;
  }
  moveDeal(deal, { stage_id: stageId });
};

const openNewDeal = stageId => dealFormRef.value?.open({ stageId });
const openDeal = deal => dealDetailRef.value?.open(deal);

const onDealCreated = async deal => {
  await fetchDeals();
  openDeal(deal);
};

const askDealDelete = deal => {
  dealToDelete.value = deal;
  dealDeleteDialogRef.value?.open();
};

const confirmDealDelete = async () => {
  isMovingDeal.value = true;
  try {
    await CrmDealsAPI.delete(dealToDelete.value.id);
    useAlert(t('CRM_DEALS.API.DELETE_SUCCESS'));
    dealDeleteDialogRef.value?.close();
    dealDetailRef.value?.close();
    await fetchDeals();
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string'
        ? message
        : t('CRM_PIPELINES.API.DELETE_ERROR')
    );
  } finally {
    isMovingDeal.value = false;
  }
};

const fetchSettings = async () => {
  if (!isAdmin.value) return;
  try {
    const { data } = await CrmSettingsAPI.get();
    autoCreateDeals.value = data.auto_create_deals;
    leadAlertDays.value = data.lead_entry.alert_after_days;
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.FETCH_ERROR');
  }
};

const fetchPipelines = async () => {
  try {
    const { data } = await CrmPipelinesAPI.get();
    pipelines.value = data.payload;
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.FETCH_ERROR');
  } finally {
    isFetching.value = false;
  }
};

const selectPipeline = pipeline => {
  router.push({
    name: 'crm_pipelines_show',
    params: { ...route.params, pipelineId: pipeline.id },
  });
};

const nextStage = stage => {
  const stages = selectedPipeline.value.stages;
  return stages[stages.findIndex(item => item.id === stage.id) + 1];
};

const stageMenuItems = stage => {
  if (CLOSING_STAGE_TYPES.includes(stage.stage_type)) {
    return [
      {
        label: t('CRM_PIPELINES.STAGE.MENU.EDIT_CLOSING'),
        value: 'edit',
        action: 'edit',
        icon: 'i-lucide-pencil',
      },
      {
        label: t('CRM_PIPELINES.STAGE.MENU.IMPULSES'),
        value: 'impulses',
        action: 'impulses',
        icon: 'i-lucide-send',
      },
    ];
  }
  const items = [
    {
      label: t('CRM_PIPELINES.STAGE.MENU.EDIT'),
      value: 'edit',
      action: 'edit',
      icon: 'i-lucide-pencil',
    },
    {
      label: t('CRM_PIPELINES.STAGE.MENU.REQUIREMENTS'),
      value: 'requirements',
      action: 'requirements',
      icon: 'i-lucide-lock',
    },
    {
      label: t('CRM_PIPELINES.STAGE.MENU.IMPULSES'),
      value: 'impulses',
      action: 'impulses',
      icon: 'i-lucide-send',
    },
  ];
  if (stage.stage_type === 'custom') {
    items.push(
      {
        label: t('CRM_PIPELINES.STAGE.MENU.MOVE_RIGHT'),
        value: 'move_right',
        action: 'move_right',
        icon: 'i-lucide-arrow-right',
        disabled: nextStage(stage)?.stage_type !== 'custom',
      },
      {
        label: t('CRM_PIPELINES.STAGE.MENU.DELETE'),
        value: 'delete',
        action: 'delete',
        icon: 'i-lucide-trash-2',
      }
    );
  }
  return items;
};

const openStageDialog = ({
  stage = null,
  after = null,
  focusRequirements = false,
}) =>
  stageDialogRef.value?.open({
    pipeline: selectedPipeline.value,
    stage,
    after,
    focusRequirements,
  });

const askStageDelete = stage => {
  stageToDelete.value = stage;
  stageTransferTarget.value = null;
  stageDeleteDialogRef.value?.open();
};

const moveStageRight = async stage => {
  const openIds = selectedPipeline.value.stages
    .filter(item => !CLOSING_STAGE_TYPES.includes(item.stage_type))
    .map(item => item.id);
  const index = openIds.indexOf(stage.id);
  [openIds[index], openIds[index + 1]] = [openIds[index + 1], openIds[index]];
  try {
    await CrmPipelinesAPI.reorderStages(selectedPipeline.value.id, openIds);
    await fetchPipelines();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  }
};

const handleStageAction = (stage, { action }) => {
  openStageMenuId.value = null;
  if (action === 'edit') openStageDialog({ stage });
  if (action === 'requirements') {
    openStageDialog({ stage, focusRequirements: true });
  }
  if (action === 'impulses') {
    impulsesDialogRef.value?.open({ pipeline: selectedPipeline.value, stage });
  }
  if (action === 'move_right') moveStageRight(stage);
  if (action === 'delete') askStageDelete(stage);
};

const confirmStageDelete = async () => {
  isSaving.value = true;
  try {
    await CrmPipelinesAPI.deleteStage(
      selectedPipeline.value.id,
      stageToDelete.value.id,
      stageTransferTarget.value
    );
    useAlert(t('CRM_PIPELINES.STAGE.API.DELETE_SUCCESS'));
    stageDeleteDialogRef.value?.close();
    await fetchPipelines();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.DELETE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const openCreateDialog = () => settingsDialogRef.value?.open();

const onPipelineSaved = async pipeline => {
  if (pipeline) selectPipeline(pipeline);
  await Promise.all([fetchPipelines(), fetchSettings()]);
};

const setAsDefault = async pipeline => {
  try {
    await CrmPipelinesAPI.update(pipeline.id, {
      pipeline: { is_default: true },
    });
    useAlert(t('CRM_PIPELINES.API.DEFAULT_SUCCESS', { name: pipeline.name }));
    await fetchPipelines();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  }
};

const confirmDelete = async () => {
  isSaving.value = true;
  try {
    await CrmPipelinesAPI.delete(pipelineToDelete.value.id);
    useAlert(t('CRM_PIPELINES.API.DELETE_SUCCESS'));
    deleteDialogRef.value?.close();
    if (selectedPipeline.value?.id === pipelineToDelete.value.id) {
      router.push({ name: 'crm_pipelines_index', params: route.params });
    }
    await fetchPipelines();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.DELETE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const handlePipelineAction = (pipeline, { action }) => {
  openPipelineMenuId.value = null;
  isSettingsMenuOpen.value = false;
  if (['edit', 'card', 'lead_entry'].includes(action)) {
    settingsDialogRef.value?.open(
      pipeline,
      action === 'edit' ? 'pipeline' : action
    );
  }
  if (action === 'ai') aiDialogRef.value?.open();
  if (action === 'set_default') setAsDefault(pipeline);
  if (action === 'delete') {
    pipelineToDelete.value = pipeline;
    deleteDialogRef.value?.open();
  }
};

const togglePipelineMenu = pipeline => {
  openPipelineMenuId.value =
    openPipelineMenuId.value === pipeline.id ? null : pipeline.id;
};

watch(
  () => route.params.pipelineId,
  () => {
    isSettingsMenuOpen.value = false;
  }
);

watch(
  () => selectedPipeline.value?.id,
  () => {
    boardState.value = defaultBoardState();
    fetchDeals();
  }
);
// Reminder toasts link here with ?deal=<id> to open the deal detail.
watch(
  [() => route.query.deal, isFetching],
  async ([dealId, fetching]) => {
    if (!dealId || fetching) return;
    await nextTick();
    dealDetailRef.value?.open({ id: Number(dealId) });
    router.replace({ query: {} });
  },
  { immediate: true }
);
watch(() => selectedPipeline.value?.stages, rebuildColumns);
watch(visibleDeals, rebuildColumns);
watch(needsAllDeals, fetchDeals);

const stageDealsCount = computed(
  () => (columns.value[stageToDelete.value?.id] || []).length
);
const transferOptions = computed(() =>
  (selectedPipeline.value?.stages || []).filter(
    stage => !isClosingStage(stage) && stage.id !== stageToDelete.value?.id
  )
);

onMounted(() => {
  store.dispatch('labels/get');
  store.dispatch('attributes/get');
  if (isAdmin.value) store.dispatch('agents/get');
  return Promise.all([fetchPipelines(), fetchSettings()]);
});
</script>

<template>
  <section class="flex w-full h-full overflow-hidden bg-n-surface-1">
    <div v-if="isFetching" class="flex items-center justify-center w-full">
      <Spinner />
    </div>

    <template v-else>
      <aside
        v-if="isPanelCollapsed"
        class="flex flex-col items-center w-12 h-full pt-5 border-e shrink-0 border-n-weak"
      >
        <Button
          icon="i-lucide-chevron-right"
          slate
          ghost
          sm
          :aria-label="t('CRM_PIPELINES.EXPAND_PANEL')"
          @click="togglePanel"
        />
      </aside>
      <aside
        v-else
        class="flex flex-col w-64 h-full border-e shrink-0 border-n-weak bg-n-surface-1"
      >
        <div class="flex flex-col gap-3 px-4 pt-5 pb-3">
          <div class="flex items-center justify-between">
            <h1 class="text-heading-2 text-n-slate-12">
              {{ t('CRM_PIPELINES.HEADER') }}
            </h1>
            <Button
              icon="i-lucide-chevron-left"
              slate
              ghost
              xs
              :aria-label="t('CRM_PIPELINES.COLLAPSE_PANEL')"
              @click="togglePanel"
            />
          </div>
          <div class="relative">
            <span
              class="absolute i-lucide-search size-3.5 top-2.5 start-3 text-n-slate-10"
            />
            <input
              v-model="searchQuery"
              type="search"
              :placeholder="t('CRM_PIPELINES.SEARCH_PLACEHOLDER')"
              class="reset-base w-full h-9 ps-9 pe-3 text-sm rounded-lg border border-n-weak bg-n-alpha-black2 text-n-slate-12 focus:outline-none focus:border-n-brand"
            />
          </div>
        </div>

        <ul class="flex flex-col flex-1 gap-1 px-2 overflow-y-auto">
          <template v-for="group in groupedPipelines" :key="group.name">
            <li
              v-if="group.name"
              class="px-2 pt-3 pb-1 text-label-small text-n-slate-10 uppercase"
            >
              {{ group.name }}
            </li>
            <li
              v-for="pipeline in group.items"
              :key="pipeline.id"
              class="relative flex items-center gap-2 px-2 rounded-lg h-9 group"
              :class="
                selectedPipeline?.id === pipeline.id
                  ? 'bg-n-alpha-2 text-n-slate-12'
                  : 'text-n-slate-11 hover:bg-n-alpha-1'
              "
            >
              <button
                type="button"
                class="flex items-center flex-1 min-w-0 gap-2 text-start"
                @click="selectPipeline(pipeline)"
              >
                <span class="i-lucide-funnel size-4 shrink-0" />
                <span class="text-sm truncate">{{ pipeline.name }}</span>
                <span class="text-label-small text-n-slate-10 shrink-0">
                  {{ pipeline.open_deals_count }}
                </span>
                <span
                  v-if="pipeline.is_default"
                  class="px-1.5 rounded text-label-small bg-n-brand/10 text-n-blue-11 shrink-0"
                >
                  {{ t('CRM_PIPELINES.DEFAULT_BADGE') }}
                </span>
              </button>
              <div
                v-if="isAdmin"
                v-on-click-outside="
                  () =>
                    openPipelineMenuId === pipeline.id &&
                    togglePipelineMenu(pipeline)
                "
                class="relative"
              >
                <Button
                  icon="i-lucide-ellipsis"
                  slate
                  ghost
                  xs
                  :aria-label="t('CRM_PIPELINES.MENU.LABEL')"
                  @click="togglePipelineMenu(pipeline)"
                />
                <DropdownMenu
                  v-if="openPipelineMenuId === pipeline.id"
                  class="top-full end-0 mt-1 w-52"
                  :menu-items="pipelineMenuItems(pipeline)"
                  @action="handlePipelineAction(pipeline, $event)"
                />
              </div>
            </li>
          </template>
          <li
            v-if="pipelines.length && !filteredPipelines.length"
            class="px-2 py-3 text-sm text-n-slate-11"
          >
            {{ t('CRM_PIPELINES.NO_SEARCH_RESULTS') }}
          </li>
        </ul>

        <div v-if="isAdmin" class="p-3 border-t border-n-weak">
          <button
            type="button"
            class="flex items-center justify-center w-full gap-2 text-sm border border-dashed rounded-lg h-9 border-n-strong text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1"
            @click="openCreateDialog"
          >
            <span class="i-lucide-plus size-4" />
            {{ t('CRM_PIPELINES.ADD_PIPELINE') }}
          </button>
        </div>
      </aside>

      <main v-if="selectedPipeline" class="flex flex-col flex-1 min-w-0 h-full">
        <header class="flex items-center gap-2 px-6 pt-5 pb-4">
          <h2 class="text-2xl font-bold text-n-slate-12 truncate">
            {{ selectedPipeline.name }}
          </h2>
          <span
            v-if="selectedPipeline.is_default"
            class="px-2 py-0.5 rounded-md text-label-small bg-n-brand/10 text-n-blue-11"
          >
            {{ t('CRM_PIPELINES.DEFAULT_BADGE') }}
          </span>
          <div
            v-if="isAdmin"
            v-on-click-outside="() => (isSettingsMenuOpen = false)"
            class="relative"
          >
            <Button
              icon="i-lucide-settings"
              slate
              ghost
              sm
              :aria-label="t('CRM_PIPELINES.MENU.SETTINGS')"
              @click="isSettingsMenuOpen = !isSettingsMenuOpen"
            />
            <DropdownMenu
              v-if="isSettingsMenuOpen"
              class="top-full start-0 mt-1 w-52"
              :menu-items="settingsMenuItems"
              @action="handlePipelineAction(selectedPipeline, $event)"
            />
          </div>
          <div class="flex items-center gap-3 ms-auto text-sm">
            <span
              v-if="waitingLeadsCount"
              class="flex items-center gap-1.5 h-7 px-2.5 rounded-lg bg-n-amber-3 text-n-amber-11"
            >
              <span class="i-lucide-alarm-clock size-3.5" />
              {{ waitingLeadsLabel }}
            </span>
            <template v-if="showLeadEntryHint">
              <button
                type="button"
                class="text-n-blue-11 hover:underline"
                :title="t('CRM_PIPELINES.LEAD_ENTRY_HINT.TOOLTIP')"
                @click="settingsDialogRef?.open(selectedPipeline, 'lead_entry')"
              >
                {{ t('CRM_PIPELINES.LEAD_ENTRY_HINT.ENABLE') }}
              </button>
              <button
                type="button"
                class="text-n-slate-11 hover:text-n-slate-12"
                @click="dismissLeadEntryHint"
              >
                {{ t('CRM_PIPELINES.LEAD_ENTRY_HINT.DISMISS') }}
              </button>
            </template>
            <button
              type="button"
              class="flex items-center gap-1.5 h-9 px-4 text-sm font-medium text-white rounded-xl bg-n-brand hover:bg-n-brand/90"
              @click="openNewDeal()"
            >
              <span class="i-lucide-plus size-4" />
              {{ t('CRM_DEALS.NEW', { item: itemLabel(selectedPipeline, 1) }) }}
            </button>
          </div>
        </header>

        <div class="px-6 py-3 border-y border-n-weak">
          <BoardToolbar
            v-model="boardState"
            :stages="selectedPipeline.stages"
            :summary="headerSummary"
          />
        </div>

        <div class="flex flex-1 min-h-0 gap-3.5 px-6 py-4 overflow-x-auto">
          <div
            v-for="stage in selectedPipeline.stages"
            :key="stage.id"
            class="flex flex-col w-[17rem] shrink-0"
          >
            <div
              class="h-0.5 mb-3 rounded-full"
              :style="{ backgroundColor: stage.color }"
            />
            <div class="flex items-center gap-1.5 group/stage min-h-7">
              <span
                v-if="CLOSING_STAGE_TYPES.includes(stage.stage_type)"
                class="size-4 shrink-0"
                :class="
                  stage.stage_type === 'won'
                    ? 'i-lucide-hourglass text-n-teal-11'
                    : 'i-lucide-circle-x text-n-ruby-11'
                "
              />
              <span class="text-sm font-medium text-n-slate-12 truncate">
                {{ stage.name }}
              </span>
              <span
                v-if="stage.stage_type === 'initial' && waitingLeadsCount"
                v-tooltip.top="waitingLeadsLabel"
                class="flex items-center gap-1 px-1.5 rounded-md text-label-small bg-n-amber-3 text-n-amber-11 shrink-0"
              >
                <span class="i-lucide-alarm-clock size-3" />
                {{ waitingLeadsCount }}
              </span>
              <span
                v-if="CLOSING_STAGE_TYPES.includes(stage.stage_type)"
                class="ms-auto text-label-small text-n-slate-11 shrink-0"
              >
                {{ closedWindowLabel }}
              </span>
              <div
                v-if="isAdmin"
                class="flex items-center gap-0.5 shrink-0"
                :class="{
                  'ms-auto': !CLOSING_STAGE_TYPES.includes(stage.stage_type),
                }"
              >
                <Button
                  v-if="!CLOSING_STAGE_TYPES.includes(stage.stage_type)"
                  v-tooltip.top="t('CRM_PIPELINES.STAGE.ADD_AFTER')"
                  icon="i-lucide-plus"
                  slate
                  ghost
                  xs
                  class="opacity-0 group-hover/stage:opacity-100 focus:opacity-100"
                  :aria-label="t('CRM_PIPELINES.STAGE.ADD_AFTER')"
                  @click="openStageDialog({ after: stage.id })"
                />
                <div
                  v-on-click-outside="
                    () =>
                      openStageMenuId === stage.id && (openStageMenuId = null)
                  "
                  class="relative"
                >
                  <Button
                    icon="i-lucide-ellipsis"
                    slate
                    ghost
                    xs
                    :aria-label="
                      t('CRM_PIPELINES.STAGE.MENU_LABEL', { name: stage.name })
                    "
                    @click="
                      openStageMenuId =
                        openStageMenuId === stage.id ? null : stage.id
                    "
                  />
                  <DropdownMenu
                    v-if="openStageMenuId === stage.id"
                    class="top-full end-0 mt-1 w-56"
                    :menu-items="stageMenuItems(stage)"
                    @action="handleStageAction(stage, $event)"
                  />
                </div>
              </div>
            </div>
            <span class="mb-3 text-xs font-medium text-n-slate-11">
              {{ stageSummary(stage) }}
            </span>
            <div
              class="relative flex flex-col flex-1 min-h-0 border rounded-2xl border-n-weak bg-n-solid-1"
            >
              <Draggable
                :list="columns[stage.id] || []"
                group="deals"
                item-key="id"
                class="flex flex-col flex-1 gap-2 p-2 overflow-y-auto"
                ghost-class="opacity-40"
                @change="onColumnChange(stage, $event)"
              >
                <template #item="{ element }">
                  <DealCard
                    :deal="element"
                    :stage="stage"
                    :pipeline="selectedPipeline"
                    :show-value="showValue"
                    @open="openDeal"
                    @move="moveDialogRef?.open($event)"
                  />
                </template>
              </Draggable>
              <span
                v-if="!(columns[stage.id] || []).length"
                class="absolute inset-0 flex items-center justify-center px-6 text-sm text-center pointer-events-none text-n-slate-10"
              >
                {{ emptyStageMessage(stage) }}
              </span>
              <button
                v-if="!CLOSING_STAGE_TYPES.includes(stage.stage_type)"
                type="button"
                class="flex items-center justify-center gap-1.5 py-3 text-sm border-t border-n-weak text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1 rounded-b-2xl"
                @click="openNewDeal(stage.id)"
              >
                <span class="i-lucide-plus size-4" />
                {{
                  t('CRM_DEALS.NEW', { item: itemLabel(selectedPipeline, 1) })
                }}
              </button>
            </div>
          </div>
        </div>
      </main>

      <main
        v-else
        class="flex flex-col items-center justify-center flex-1 gap-4 px-6 text-center"
      >
        <span class="i-lucide-funnel size-10 text-n-slate-10" />
        <div class="flex flex-col gap-1">
          <span class="text-heading-2 text-n-slate-12">
            {{ t('CRM_PIPELINES.EMPTY.TITLE') }}
          </span>
          <span class="text-body-main text-n-slate-11">
            {{
              isAdmin
                ? t('CRM_PIPELINES.EMPTY.ADMIN')
                : t('CRM_PIPELINES.EMPTY.AGENT')
            }}
          </span>
        </div>
        <Button
          v-if="isAdmin"
          :label="t('CRM_PIPELINES.CREATE_BUTTON')"
          icon="i-lucide-plus"
          @click="openCreateDialog"
        />
      </main>
    </template>

    <PipelineSettingsDialog
      ref="settingsDialogRef"
      :has-default-pipeline="hasDefaultPipeline"
      @saved="onPipelineSaved"
    />
    <AiSettingsDialog ref="aiDialogRef" />
    <DealFormDialog
      ref="dealFormRef"
      :pipeline="selectedPipeline"
      :item-label="itemLabel(selectedPipeline, 1)"
      @created="onDealCreated"
    />
    <DealDetailDialog
      ref="dealDetailRef"
      :pipeline="selectedPipeline"
      @changed="fetchDeals"
      @close-request="closeDialogRef?.open($event)"
      @move="moveDialogRef?.open($event)"
      @delete="askDealDelete"
    />
    <CloseDealDialog
      ref="closeDialogRef"
      :is-loading="isMovingDeal"
      @confirm="confirmCloseDeal"
      @cancel="rebuildColumns"
    />
    <MoveDealDialog
      ref="moveDialogRef"
      :pipeline="selectedPipeline"
      @move="onMoveDialog"
    />
    <Dialog
      ref="dealDeleteDialogRef"
      type="alert"
      :title="t('CRM_DEALS.DELETE.TITLE')"
      :description="
        t('CRM_DEALS.DELETE.MESSAGE', {
          number: dealToDelete?.number,
          name: dealToDelete?.display_name,
        })
      "
      :confirm-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.YES')"
      :cancel-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.NO')"
      :is-loading="isMovingDeal"
      @confirm="confirmDealDelete"
    />
    <ImpulsesDialog ref="impulsesDialogRef" />
    <StageDialog
      ref="stageDialogRef"
      @saved="fetchPipelines"
      @delete="askStageDelete"
    />
    <Dialog
      ref="stageDeleteDialogRef"
      type="alert"
      :title="t('CRM_PIPELINES.STAGE.DELETE_CONFIRM.TITLE')"
      :description="
        t('CRM_PIPELINES.STAGE.DELETE_CONFIRM.MESSAGE', {
          name: stageToDelete?.name,
        })
      "
      :confirm-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.YES')"
      :cancel-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.NO')"
      :disable-confirm-button="stageDealsCount > 0 && !stageTransferTarget"
      :is-loading="isSaving"
      @confirm="confirmStageDelete"
    >
      <label v-if="stageDealsCount > 0" class="flex flex-col gap-1.5">
        <span class="text-sm text-n-slate-12">
          {{ t('CRM_DEALS.STAGE_DELETE.TRANSFER', { count: stageDealsCount }) }}
        </span>
        <select
          v-model="stageTransferTarget"
          class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
        >
          <option :value="null" disabled>
            {{ t('CRM_DEALS.MOVE.CHOOSE') }}
          </option>
          <option
            v-for="stage in transferOptions"
            :key="stage.id"
            :value="stage.id"
          >
            {{ stage.name }}
          </option>
        </select>
      </label>
    </Dialog>
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('CRM_PIPELINES.DELETE_CONFIRM.TITLE')"
      :description="
        t('CRM_PIPELINES.DELETE_CONFIRM.MESSAGE', {
          name: pipelineToDelete?.name,
        })
      "
      :confirm-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.YES')"
      :cancel-button-label="t('CRM_PIPELINES.DELETE_CONFIRM.NO')"
      :is-loading="isSaving"
      @confirm="confirmDelete"
    />
  </section>
</template>
