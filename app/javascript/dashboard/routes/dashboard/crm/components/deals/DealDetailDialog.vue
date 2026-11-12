<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import StagePill from './detail/StagePill.vue';
import LinkContactCard from './detail/LinkContactCard.vue';
import CompanyPicker from './CompanyPicker.vue';
import DealCustomFields from './detail/DealCustomFields.vue';
import ContactLabels from './detail/ContactLabels.vue';
import DealInfoTab from './detail/DealInfoTab.vue';
import DealHistoryTab from './detail/DealHistoryTab.vue';
import DealContactDealsTab from './detail/DealContactDealsTab.vue';
import DealConversationsTab from './detail/DealConversationsTab.vue';
import DealActivitiesTab from './detail/DealActivitiesTab.vue';
import ActivityFormDialog from './detail/ActivityFormDialog.vue';
import DealFilesTab from './detail/DealFilesTab.vue';
import DealImpulsesTab from './detail/DealImpulsesTab.vue';
import DealAiInsights from './detail/DealAiInsights.vue';
import DealTemperature from './DealTemperature.vue';
import { isClosingStage } from '../../dealHelpers';

const props = defineProps({
  pipeline: { type: Object, default: null },
});

const emit = defineEmits(['changed', 'closeRequest', 'move', 'delete']);

const TABS = [
  'info',
  'history',
  'activities',
  'impulses',
  'deals',
  'files',
  'conversations',
];

const { t } = useI18n();
const { isAdmin } = useAdmin();
const agents = useMapGetter('agents/getAgents');

const dialogRef = ref(null);
const activityFormRef = ref(null);
const deal = ref(null);
const isLoading = ref(false);
const activeTab = ref('info');
const isMenuOpen = ref(false);
const notesDraft = ref('');

const showValue = computed(
  () => props.pipeline?.pipeline_type !== 'management'
);

const STATUS_DOT = {
  open: 'bg-n-blue-9',
  won: 'bg-n-teal-9',
  lost: 'bg-n-ruby-9',
};

const menuItems = computed(() => [
  ...(props.pipeline?.stages || [])
    .filter(stage => isClosingStage(stage) && stage.id !== deal.value?.stage_id)
    .map(stage => ({
      label:
        stage.stage_type === 'won'
          ? t('CRM_DEALS.MENU.WIN')
          : t('CRM_DEALS.MENU.LOSE'),
      value: `close-${stage.id}`,
      action: 'close',
      stage,
      icon:
        stage.stage_type === 'won'
          ? 'i-lucide-hourglass'
          : 'i-lucide-thumbs-down',
    })),
  {
    label: t('CRM_DEALS.MENU.MOVE'),
    value: 'move',
    action: 'move',
    icon: 'i-lucide-arrow-left-right',
  },
  {
    label: t('CRM_DEALS.MENU.DUPLICATE'),
    value: 'duplicate',
    action: 'duplicate',
    icon: 'i-lucide-copy',
  },
  {
    label: t('CRM_DEALS.MENU.DELETE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash-2',
  },
]);

const load = async id => {
  isLoading.value = true;
  try {
    const { data } = await CrmDealsAPI.show(id);
    deal.value = data;
    notesDraft.value = data.notes || '';
  } catch (error) {
    useAlert(t('CRM_DEALS.API.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const open = target => {
  deal.value = null;
  activeTab.value = 'info';
  isMenuOpen.value = false;
  dialogRef.value?.showModal();
  load(target.id);
};

const close = () => dialogRef.value?.close();
const reload = () => deal.value && load(deal.value.id);

const openActivityForm = activity =>
  activityFormRef.value?.open({ deal: deal.value, activity });

const openSuggestedActivity = suggestion =>
  activityFormRef.value?.open({ deal: deal.value, suggestion });

const onAnalyzed = data => {
  deal.value = data;
  emit('changed');
};

const onActivityChanged = async () => {
  await reload();
  emit('changed');
};

const update = async (changes, notify = true) => {
  try {
    const { data } = await CrmDealsAPI.update(deal.value.id, { deal: changes });
    deal.value = data;
    notesDraft.value = data.notes || '';
    if (notify) useAlert(t('CRM_DEALS.API.UPDATE_SUCCESS'));
    emit('changed');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
    await reload();
  }
};

const onStageSelect = stage => {
  if (isClosingStage(stage)) {
    emit('closeRequest', { deal: deal.value, stage });
    return;
  }
  update({ stage_id: stage.id });
};

const saveNotes = () => {
  if (notesDraft.value !== (deal.value.notes || ''))
    update({ notes: notesDraft.value }, false);
};

const handleMenu = async ({ action, stage }) => {
  isMenuOpen.value = false;
  if (action === 'close') emit('closeRequest', { deal: deal.value, stage });
  if (action === 'move') emit('move', deal.value);
  if (action === 'delete') emit('delete', deal.value);
  if (action === 'duplicate') {
    try {
      const { data } = await CrmDealsAPI.duplicate(deal.value.id);
      useAlert(t('CRM_DEALS.API.DUPLICATE_SUCCESS', { number: data.number }));
      emit('changed');
      await load(data.id);
    } catch (error) {
      useAlert(t('CRM_PIPELINES.API.SAVE_ERROR'));
    }
  }
};

const onBackdropClick = event => {
  if (event.target === dialogRef.value) close();
};

defineExpose({ open, reload, close });
</script>

<template>
  <dialog
    ref="dialogRef"
    class="p-0 m-auto overflow-hidden border w-[min(96vw,110rem)] h-[92vh] max-w-none max-h-none rounded-3xl border-n-weak bg-n-solid-1 text-n-slate-12 backdrop:bg-n-alpha-black1 backdrop:backdrop-blur-sm"
    @click="onBackdropClick"
  >
    <div v-if="!deal" class="flex items-center justify-center h-full">
      <Spinner />
    </div>
    <div v-else class="flex flex-col h-full">
      <header
        class="flex items-start justify-between gap-4 px-8 py-6 border-b border-n-weak"
      >
        <div class="flex flex-col gap-2 min-w-0">
          <div class="flex items-baseline gap-2.5 min-w-0">
            <span class="text-base text-n-slate-11">
              {{ t('CRM_DEALS.NUMBER', { number: deal.number }) }}
            </span>
            <h2 class="text-2xl font-bold truncate text-n-slate-12">
              {{ deal.display_name }}
            </h2>
          </div>
          <div class="flex items-center gap-2">
            <span
              class="flex items-center gap-2 px-3 py-1 text-sm border rounded-lg border-n-slate-6 text-n-slate-12"
            >
              <span
                class="rounded-full size-2"
                :class="STATUS_DOT[deal.status]"
              />
              {{ t(`CRM_DEALS.STATUS.${deal.status.toUpperCase()}`) }}
            </span>
            <DealTemperature
              v-if="deal.ai_temperature"
              :temperature="deal.ai_temperature"
              :reason="deal.ai_temperature_reason"
            />
          </div>
        </div>
        <div class="flex items-center gap-3">
          <StagePill
            :stages="props.pipeline?.stages || []"
            :stage-id="deal.stage_id"
            @select="onStageSelect"
          />
          <button
            type="button"
            class="flex items-center gap-2 h-11 px-4 text-base font-medium rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1"
            @click="openActivityForm(null)"
          >
            <span class="i-lucide-plus size-4" />
            {{ t('CRM_DEALS.DETAIL.NEW_ACTIVITY') }}
          </button>
          <div v-on-click-outside="() => (isMenuOpen = false)" class="relative">
            <button
              type="button"
              class="flex items-center justify-center rounded-xl size-11 outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1"
              :aria-label="t('CRM_DEALS.MENU.LABEL')"
              @click="isMenuOpen = !isMenuOpen"
            >
              <span class="i-lucide-ellipsis size-5" />
            </button>
            <DropdownMenu
              v-if="isMenuOpen"
              class="top-full end-0 mt-1 w-52"
              :menu-items="menuItems"
              @action="handleMenu"
            />
          </div>
          <button
            type="button"
            class="flex items-center justify-center rounded-xl size-11 text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12"
            :aria-label="t('CRM_DEALS.DETAIL.CLOSE')"
            @click="close"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>
      </header>

      <div class="grid flex-1 min-h-0 grid-cols-[28rem_minmax(0,1fr)]">
        <aside
          class="flex flex-col gap-6 p-7 overflow-y-auto border-e border-n-weak"
        >
          <DealAiInsights
            v-if="deal.ai_features.length"
            :deal="deal"
            @analyzed="onAnalyzed"
            @create-activity="openSuggestedActivity"
          />
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-11">
              {{ t('CRM_DEALS.COMPANY.LABEL') }}
            </span>
            <CompanyPicker
              :model-value="deal.company"
              @update:model-value="update({ company_id: $event?.id || null })"
            />
          </div>
          <LinkContactCard
            :contact="deal.contact"
            @link="update({ contact_id: $event.id })"
            @unlink="update({ contact_id: null })"
          />
          <ContactLabels :contact-id="deal.contact?.id || null" />
          <label class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-11">{{
              t('CRM_DEALS.FORM.ASSIGNEE')
            }}</span>
            <select
              :value="deal.assignee.id"
              :disabled="!isAdmin"
              class="reset-base h-12 ps-4 pe-8 text-base font-medium rounded-xl border border-n-slate-6 bg-transparent text-n-slate-12 disabled:opacity-80"
              @change="update({ assignee_id: Number($event.target.value) })"
            >
              <option v-if="!isAdmin" :value="deal.assignee.id">
                {{ deal.assignee.name }}
              </option>
              <template v-else>
                <option
                  v-for="agent in agents"
                  :key="agent.id"
                  :value="agent.id"
                >
                  {{ agent.available_name || agent.name }}
                </option>
              </template>
            </select>
          </label>
          <label class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-11">{{
              t('CRM_DEALS.DETAIL.NOTES')
            }}</span>
            <textarea
              v-model="notesDraft"
              rows="3"
              :placeholder="t('CRM_DEALS.DETAIL.NOTES_PLACEHOLDER')"
              class="reset-base px-4 py-3 text-base rounded-xl border border-n-slate-6 bg-transparent text-n-slate-12 resize-y"
              @blur="saveNotes"
            />
          </label>
          <section class="flex flex-col gap-3">
            <span class="text-sm font-medium text-n-slate-11">{{
              t('CRM_DEALS.DETAIL.DEAL_FIELDS')
            }}</span>
            <label class="flex items-center justify-between gap-3">
              <span class="text-base text-n-slate-11">{{
                t('CRM_DEALS.FORM.EXPECTED_CLOSE_DATE')
              }}</span>
              <input
                type="date"
                :value="deal.expected_close_date"
                class="reset-base h-11 px-3 text-base rounded-xl border border-n-slate-6 bg-transparent text-n-slate-12"
                @change="
                  update({ expected_close_date: $event.target.value || null })
                "
              />
            </label>
            <DealCustomFields :deal="deal" @update="update" />
          </section>
          <div
            v-if="deal.close_reason"
            class="flex flex-col gap-1 p-4 rounded-xl bg-n-alpha-1"
          >
            <span class="text-label-small text-n-slate-11">
              {{
                deal.status === 'won'
                  ? t('CRM_DEALS.CLOSE.WIN_REASON')
                  : t('CRM_DEALS.CLOSE.LOSE_REASON')
              }}
            </span>
            <span class="text-sm text-n-slate-12">
              {{ t(`CRM_DEALS.REASONS.${deal.close_reason.toUpperCase()}`) }}
            </span>
            <span
              v-if="deal.close_note"
              class="text-label-small text-n-slate-11"
            >
              {{ deal.close_note }}
            </span>
          </div>
        </aside>

        <section class="flex flex-col min-h-0">
          <nav class="flex gap-7 px-8 border-b border-n-weak">
            <button
              v-for="tab in TABS"
              :key="tab"
              type="button"
              class="py-4 -mb-px text-base border-b-2"
              :class="
                activeTab === tab
                  ? 'border-n-blue-9 text-n-blue-11'
                  : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
              "
              @click="activeTab = tab"
            >
              {{ t(`CRM_DEALS.DETAIL.TABS.${tab.toUpperCase()}`) }}
            </button>
          </nav>
          <div class="relative flex-1 min-h-0 px-8 py-7 overflow-y-auto">
            <DealInfoTab
              v-if="activeTab === 'info'"
              :deal="deal"
              :pipeline="props.pipeline"
              :show-value="showValue"
              @update="update"
            />
            <DealHistoryTab
              v-else-if="activeTab === 'history'"
              :events="deal.events"
            />
            <DealActivitiesTab
              v-else-if="activeTab === 'activities'"
              :deal="deal"
              @new="openActivityForm(null)"
              @edit="openActivityForm"
              @changed="onActivityChanged"
            />
            <DealImpulsesTab
              v-else-if="activeTab === 'impulses'"
              :deal="deal"
              @changed="onActivityChanged"
            />
            <DealContactDealsTab
              v-else-if="activeTab === 'deals'"
              :deal="deal"
              @open="load($event.id)"
            />
            <DealConversationsTab
              v-else-if="activeTab === 'conversations'"
              :contact="deal.contact"
            />
            <DealFilesTab
              v-else-if="activeTab === 'files'"
              :deal="deal"
              @changed="onActivityChanged"
            />
            <div
              v-if="isLoading"
              class="absolute inset-0 flex items-center justify-center bg-n-alpha-black1"
            >
              <Spinner />
            </div>
          </div>
        </section>
      </div>
    </div>
    <ActivityFormDialog ref="activityFormRef" @saved="onActivityChanged" />
  </dialog>
</template>
