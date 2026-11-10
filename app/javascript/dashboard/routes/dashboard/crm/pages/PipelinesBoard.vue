<script setup>
import { computed, onMounted, ref, watch } from 'vue';
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
import { useItemLabel } from '../useItemLabel';
import { CLOSING_STAGE_TYPES, UI_SETTINGS_KEYS } from '../constants';

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
const settingsDialogRef = ref(null);
const deleteDialogRef = ref(null);
const aiDialogRef = ref(null);
const stageDialogRef = ref(null);
const stageDeleteDialogRef = ref(null);
const openStageMenuId = ref(null);
const stageToDelete = ref(null);

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
  if (stage.stage_type === 'won') return t('CRM_PIPELINES.BOARD.EMPTY_WON');
  if (stage.stage_type === 'lost') return t('CRM_PIPELINES.BOARD.EMPTY_LOST');
  return t('CRM_PIPELINES.BOARD.EMPTY_STAGE', {
    item: itemLabel(selectedPipeline.value, 2).toLowerCase(),
  });
};

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const fetchSettings = async () => {
  if (!isAdmin.value) return;
  try {
    const { data } = await CrmSettingsAPI.get();
    autoCreateDeals.value = data.auto_create_deals;
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
  if (action === 'move_right') moveStageRight(stage);
  if (action === 'delete') askStageDelete(stage);
};

const confirmStageDelete = async () => {
  isSaving.value = true;
  try {
    await CrmPipelinesAPI.deleteStage(
      selectedPipeline.value.id,
      stageToDelete.value.id
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

onMounted(() => {
  if (isAdmin.value) store.dispatch('labels/get');
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
        <header class="flex items-center gap-2 px-6 py-5">
          <h2 class="text-heading-1 text-n-slate-12 truncate">
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
          <div
            v-if="showLeadEntryHint"
            class="flex items-center gap-3 ms-auto text-sm"
          >
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
          </div>
        </header>

        <div class="flex flex-1 min-h-0 gap-3 px-6 pb-6 overflow-x-auto">
          <div
            v-for="stage in selectedPipeline.stages"
            :key="stage.id"
            class="flex flex-col w-72 shrink-0"
          >
            <div
              class="h-0.5 mb-3 rounded-full"
              :style="{ backgroundColor: stage.color }"
            />
            <div class="flex items-center gap-1.5 mb-1 group/stage min-h-7">
              <span
                v-if="CLOSING_STAGE_TYPES.includes(stage.stage_type)"
                class="size-4"
                :class="
                  stage.stage_type === 'won'
                    ? 'i-lucide-trophy text-n-teal-11'
                    : 'i-lucide-circle-x text-n-ruby-11'
                "
              />
              <span class="text-heading-3 text-n-slate-12 truncate">
                {{ stage.name }}
              </span>
              <div v-if="isAdmin" class="flex items-center gap-1 ms-auto">
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
            <span class="mb-3 text-label-small text-n-slate-11">
              {{
                t('CRM_PIPELINES.BOARD.COUNT', {
                  count: 0,
                  item: itemLabel(selectedPipeline, 0).toLowerCase(),
                })
              }}
            </span>
            <div
              class="flex items-center justify-center flex-1 px-6 text-center border rounded-xl border-n-weak bg-n-solid-1"
            >
              <span class="text-body-main text-n-slate-11">
                {{ emptyStageMessage(stage) }}
              </span>
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
      :is-loading="isSaving"
      @confirm="confirmStageDelete"
    />
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
