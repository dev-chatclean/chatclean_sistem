<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PipelineFormDialog from '../components/PipelineFormDialog.vue';
import LeadEntryDialog from '../components/LeadEntryDialog.vue';
import { CLOSING_STAGE_TYPES } from '../constants';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const pipelines = ref([]);
const isFetching = ref(true);
const isSaving = ref(false);
const searchQuery = ref('');
const openPipelineMenuId = ref(null);
const isSettingsMenuOpen = ref(false);
const pipelineToDelete = ref(null);
const formDialogRef = ref(null);
const deleteDialogRef = ref(null);
const leadEntryDialogRef = ref(null);

const filteredPipelines = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return pipelines.value;
  return pipelines.value.filter(pipeline =>
    pipeline.name.toLowerCase().includes(query)
  );
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

const pipelineMenuItems = pipeline => [
  {
    label: t('CRM_PIPELINES.MENU.RENAME'),
    value: 'rename',
    action: 'rename',
    icon: 'i-lucide-pencil',
  },
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

const settingsMenuItems = computed(() => [
  {
    label: t('CRM_PIPELINES.MENU.EDIT'),
    value: 'rename',
    action: 'rename',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('CRM_PIPELINES.MENU.LEAD_ENTRY'),
    value: 'lead_entry',
    action: 'lead_entry',
    icon: 'i-lucide-funnel',
  },
]);

const emptyStageMessage = stage => {
  if (stage.stage_type === 'won') return t('CRM_PIPELINES.BOARD.EMPTY_WON');
  if (stage.stage_type === 'lost') return t('CRM_PIPELINES.BOARD.EMPTY_LOST');
  return t('CRM_PIPELINES.BOARD.EMPTY_STAGE');
};

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
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

const openCreateDialog = () => formDialogRef.value?.open();

const savePipeline = async ({ id, payload }) => {
  isSaving.value = true;
  try {
    if (id) {
      await CrmPipelinesAPI.update(id, { pipeline: payload });
      useAlert(t('CRM_PIPELINES.API.UPDATE_SUCCESS'));
    } else {
      const { data } = await CrmPipelinesAPI.create({ pipeline: payload });
      useAlert(t('CRM_PIPELINES.API.CREATE_SUCCESS'));
      selectPipeline(data);
    }
    formDialogRef.value?.close();
    await fetchPipelines();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
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
  if (action === 'rename') formDialogRef.value?.open(pipeline);
  if (action === 'set_default') setAsDefault(pipeline);
  if (action === 'lead_entry') leadEntryDialogRef.value?.open();
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

onMounted(fetchPipelines);
</script>

<template>
  <section class="flex w-full h-full overflow-hidden bg-n-surface-1">
    <div v-if="isFetching" class="flex items-center justify-center w-full">
      <Spinner />
    </div>

    <template v-else>
      <aside
        class="flex flex-col w-64 h-full border-e shrink-0 border-n-weak bg-n-surface-1"
      >
        <div class="flex flex-col gap-3 px-4 pt-5 pb-3">
          <h1 class="text-heading-2 text-n-slate-12">
            {{ t('CRM_PIPELINES.HEADER') }}
          </h1>
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
          <li
            v-for="pipeline in filteredPipelines"
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
            <div class="flex items-center gap-1.5 mb-1">
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
            </div>
            <span class="mb-3 text-label-small text-n-slate-11">
              {{ t('CRM_PIPELINES.BOARD.COUNT', { count: 0 }) }}
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

    <PipelineFormDialog
      ref="formDialogRef"
      :is-loading="isSaving"
      @submit="savePipeline"
    />
    <LeadEntryDialog
      ref="leadEntryDialogRef"
      :has-default-pipeline="hasDefaultPipeline"
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
