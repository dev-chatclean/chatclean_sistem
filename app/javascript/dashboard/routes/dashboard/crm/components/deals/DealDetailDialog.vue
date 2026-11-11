<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactPicker from './ContactPicker.vue';
import { formatCurrency, isClosingStage } from '../../dealHelpers';

const props = defineProps({
  pipeline: { type: Object, default: null },
});

const emit = defineEmits(['changed', 'closeRequest', 'move', 'delete']);

const TABS = ['info', 'history'];
const SECONDS_IN_MINUTE = 60;
const SECONDS_IN_HOUR = 3600;
const SECONDS_IN_DAY = 86400;

const { t, locale } = useI18n();
const { isAdmin } = useAdmin();
const agents = useMapGetter('agents/getAgents');

const dialogRef = ref(null);
const deal = ref(null);
const isLoading = ref(false);
const activeTab = ref('info');
const isMenuOpen = ref(false);
const valueDraft = ref('');
const notesDraft = ref('');

const showValue = computed(
  () => props.pipeline?.pipeline_type !== 'management'
);
const openStages = computed(() =>
  (props.pipeline?.stages || []).filter(stage => !isClosingStage(stage))
);
const tabs = computed(() =>
  TABS.map(key => ({
    key,
    label: t(`CRM_DEALS.DETAIL.TABS.${key.toUpperCase()}`),
  }))
);

const statusClass = computed(
  () =>
    ({
      won: 'bg-n-teal-3 text-n-teal-11',
      lost: 'bg-n-ruby-3 text-n-ruby-11',
    })[deal.value?.status] || 'bg-n-blue-3 text-n-blue-11'
);

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
        stage.stage_type === 'won' ? 'i-lucide-trophy' : 'i-lucide-thumbs-down',
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

const formatDateTime = timestamp =>
  new Intl.DateTimeFormat(locale.value.replace('_', '-'), {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(timestamp * 1000));

const formatDuration = seconds => {
  if (seconds < SECONDS_IN_MINUTE)
    return t('CRM_DEALS.DETAIL.DURATION.LESS_THAN_MINUTE');
  if (seconds < SECONDS_IN_HOUR) {
    return t('CRM_DEALS.DETAIL.DURATION.MINUTES', {
      n: Math.floor(seconds / SECONDS_IN_MINUTE),
    });
  }
  if (seconds < SECONDS_IN_DAY) {
    return t('CRM_DEALS.DETAIL.DURATION.HOURS', {
      n: Math.floor(seconds / SECONDS_IN_HOUR),
    });
  }
  return t('CRM_DEALS.DETAIL.DURATION.DAYS', {
    n: Math.floor(seconds / SECONDS_IN_DAY),
  });
};

const entryDuration = entry =>
  (entry.left_at || Math.floor(Date.now() / 1000)) - entry.entered_at;

const timeByStage = computed(() => {
  const totals = {};
  (deal.value?.journey || []).forEach(entry => {
    totals[entry.stage_name] =
      (totals[entry.stage_name] || 0) + entryDuration(entry);
  });
  return totals;
});

const eventText = event => {
  const user = event.user_name || t('CRM_DEALS.DETAIL.SYSTEM');
  return t(`CRM_DEALS.DETAIL.EVENTS.${event.event_type.toUpperCase()}`, {
    user,
    from: event.from_stage_name || event.data.from,
    to: event.to_stage_name || event.data.to,
  });
};

const load = async id => {
  isLoading.value = true;
  try {
    const { data } = await CrmDealsAPI.show(id);
    deal.value = data;
    valueDraft.value = String(data.value);
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
  dialogRef.value?.open();
  load(target.id);
};

const reload = () => deal.value && load(deal.value.id);

const update = async (changes, successKey = 'CRM_DEALS.API.UPDATE_SUCCESS') => {
  try {
    const { data } = await CrmDealsAPI.update(deal.value.id, { deal: changes });
    deal.value = data;
    valueDraft.value = String(data.value);
    notesDraft.value = data.notes || '';
    if (successKey) useAlert(t(successKey));
    emit('changed');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
    await reload();
  }
};

const onStageChange = event => {
  const stage = props.pipeline.stages.find(
    item => item.id === Number(event.target.value)
  );
  if (isClosingStage(stage)) {
    event.target.value = deal.value.stage_id;
    emit('closeRequest', { deal: deal.value, stage });
    return;
  }
  update({ stage_id: stage.id });
};

const saveValue = () => {
  const value = Number(valueDraft.value) || 0;
  if (value !== deal.value.value) update({ value });
};

const saveNotes = () => {
  if (notesDraft.value !== (deal.value.notes || ''))
    update({ notes: notesDraft.value }, null);
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

const close = () => dialogRef.value?.close();

defineExpose({ open, reload, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="5xl"
    :show-confirm-button="false"
    :show-cancel-button="false"
    overflow-y-auto
  >
    <div v-if="!deal" class="flex justify-center py-16">
      <Spinner />
    </div>
    <div v-else class="flex flex-col gap-5">
      <header class="flex flex-wrap items-start justify-between gap-3">
        <div class="flex flex-col gap-1.5 min-w-0">
          <div class="flex items-center gap-2 min-w-0">
            <span class="text-label-small text-n-slate-10">{{
              t('CRM_DEALS.NUMBER', { number: deal.number })
            }}</span>
            <h2 class="text-heading-2 text-n-slate-12 truncate">
              {{ deal.display_name }}
            </h2>
          </div>
          <span
            class="self-start px-2 py-0.5 rounded-md text-label-small"
            :class="statusClass"
          >
            {{ t(`CRM_DEALS.STATUS.${deal.status.toUpperCase()}`) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <select
            :value="deal.stage_id"
            class="reset-base h-9 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
            :aria-label="t('CRM_DEALS.FORM.STAGE')"
            @change="onStageChange"
          >
            <option
              v-for="stage in props.pipeline?.stages || []"
              :key="stage.id"
              :value="stage.id"
            >
              {{ stage.name }}
            </option>
          </select>
          <div v-on-click-outside="() => (isMenuOpen = false)" class="relative">
            <Button
              icon="i-lucide-ellipsis"
              slate
              faded
              sm
              :aria-label="t('CRM_DEALS.MENU.LABEL')"
              @click="isMenuOpen = !isMenuOpen"
            />
            <DropdownMenu
              v-if="isMenuOpen"
              class="top-full end-0 mt-1 w-52"
              :menu-items="menuItems"
              @action="handleMenu"
            />
          </div>
          <Button
            icon="i-lucide-x"
            slate
            ghost
            sm
            :aria-label="t('CRM_DEALS.DETAIL.CLOSE')"
            @click="close"
          />
        </div>
      </header>

      <div class="grid gap-5 md:grid-cols-[18rem_minmax(0,1fr)]">
        <aside class="flex flex-col gap-4">
          <div class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">{{
              t('CRM_DEALS.FORM.CONTACT')
            }}</span>
            <ContactPicker
              :model-value="deal.contact"
              @update:model-value="update({ contact_id: $event?.id || null })"
            />
          </div>
          <label class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">{{
              t('CRM_DEALS.FORM.ASSIGNEE')
            }}</span>
            <select
              :value="deal.assignee.id"
              :disabled="!isAdmin"
              class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 disabled:opacity-70"
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
          <label class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">{{
              t('CRM_DEALS.FORM.EXPECTED_CLOSE_DATE')
            }}</span>
            <input
              type="date"
              :value="deal.expected_close_date"
              class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
              @change="
                update({ expected_close_date: $event.target.value || null })
              "
            />
          </label>
          <label class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">{{
              t('CRM_DEALS.DETAIL.NOTES')
            }}</span>
            <textarea
              v-model="notesDraft"
              rows="4"
              :placeholder="t('CRM_DEALS.DETAIL.NOTES_PLACEHOLDER')"
              class="reset-base px-3 py-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 resize-y"
              @blur="saveNotes"
            />
          </label>
          <div
            v-if="deal.close_reason"
            class="flex flex-col gap-1 p-3 rounded-lg bg-n-alpha-1"
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

        <section class="flex flex-col gap-4 min-w-0">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="TABS.indexOf(activeTab)"
            @tab-changed="activeTab = $event.key"
          />

          <template v-if="activeTab === 'info'">
            <div
              v-if="showValue"
              class="flex items-center justify-between gap-3 p-4 border rounded-xl border-n-weak"
            >
              <div class="flex flex-col gap-1">
                <span class="text-label-small text-n-slate-11">{{
                  t('CRM_DEALS.DETAIL.VALUE')
                }}</span>
                <span class="text-heading-2 text-n-slate-12">{{
                  formatCurrency(deal.value)
                }}</span>
              </div>
              <input
                v-model="valueDraft"
                type="number"
                min="0"
                step="0.01"
                class="reset-base w-36 h-9 px-3 text-sm text-end rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
                :aria-label="t('CRM_DEALS.DETAIL.VALUE')"
                @blur="saveValue"
                @keydown.enter="saveValue"
              />
            </div>

            <div class="flex flex-col gap-3">
              <span class="text-label text-n-slate-12">{{
                t('CRM_DEALS.DETAIL.FULL_PIPELINE')
              }}</span>
              <ol
                class="flex items-start gap-2 p-0 pb-1 m-0 overflow-x-auto list-none"
              >
                <li
                  v-for="stage in openStages"
                  :key="stage.id"
                  class="flex flex-col items-center gap-1 min-w-24 text-center"
                >
                  <span
                    class="rounded-full size-3 border-2"
                    :class="
                      stage.id === deal.stage_id
                        ? 'border-n-brand bg-n-brand'
                        : 'border-n-slate-7'
                    "
                  />
                  <span
                    class="text-label-small"
                    :class="
                      stage.id === deal.stage_id
                        ? 'text-n-slate-12'
                        : 'text-n-slate-11'
                    "
                  >
                    {{ stage.name }}
                  </span>
                  <span
                    v-if="timeByStage[stage.name]"
                    class="text-label-small text-n-slate-10"
                  >
                    {{ formatDuration(timeByStage[stage.name]) }}
                  </span>
                </li>
              </ol>
            </div>

            <dl
              class="flex flex-col border rounded-xl border-n-weak divide-y divide-n-weak"
            >
              <div class="flex justify-between px-4 py-2.5 text-sm">
                <dt class="text-n-slate-11">
                  {{ t('CRM_DEALS.DETAIL.NUMBER') }}
                </dt>
                <dd class="text-n-slate-12">
                  {{ t('CRM_DEALS.NUMBER', { number: deal.number }) }}
                </dd>
              </div>
              <div class="flex justify-between px-4 py-2.5 text-sm">
                <dt class="text-n-slate-11">
                  {{ t('CRM_DEALS.DETAIL.CREATED_AT') }}
                </dt>
                <dd class="text-n-slate-12">
                  {{ formatDateTime(deal.created_at) }}
                </dd>
              </div>
              <div class="flex justify-between px-4 py-2.5 text-sm">
                <dt class="text-n-slate-11">
                  {{ t('CRM_DEALS.DETAIL.IN_STAGE_SINCE') }}
                </dt>
                <dd class="text-n-slate-12">
                  {{ formatDateTime(deal.stage_entered_at) }}
                </dd>
              </div>
            </dl>

            <div class="flex flex-col gap-2">
              <span class="text-label text-n-slate-12">{{
                t('CRM_DEALS.DETAIL.JOURNEY')
              }}</span>
              <ol class="flex flex-col gap-2 p-0 m-0 list-none">
                <li
                  v-for="(entry, index) in deal.journey"
                  :key="`${entry.entered_at}-${index}`"
                  class="flex items-start justify-between gap-3 text-sm"
                >
                  <div class="flex items-start gap-2">
                    <span
                      class="mt-1.5 rounded-full size-2 bg-n-brand shrink-0"
                    />
                    <div class="flex flex-col">
                      <span class="text-n-slate-12">{{
                        entry.stage_name
                      }}</span>
                      <span class="text-label-small text-n-slate-11">
                        {{
                          t('CRM_DEALS.DETAIL.RANGE', {
                            from: formatDateTime(entry.entered_at),
                            to: entry.left_at
                              ? formatDateTime(entry.left_at)
                              : t('CRM_DEALS.DETAIL.NOW'),
                          })
                        }}
                      </span>
                    </div>
                  </div>
                  <span class="text-label-small text-n-slate-11 shrink-0">
                    {{ formatDuration(entryDuration(entry)) }}
                  </span>
                </li>
              </ol>
            </div>
          </template>

          <ol v-else class="flex flex-col gap-3 p-0 m-0 list-none">
            <li
              v-for="event in [...deal.events].reverse()"
              :key="event.id"
              class="flex items-start justify-between gap-3 text-sm"
            >
              <span class="flex items-start gap-2 text-n-slate-12">
                <span
                  class="mt-1 i-lucide-history size-3.5 text-n-slate-10 shrink-0"
                />
                {{ eventText(event) }}
              </span>
              <span class="text-label-small text-n-slate-11 shrink-0">
                {{ formatDateTime(event.created_at) }}
              </span>
            </li>
          </ol>
        </section>
      </div>
      <div
        v-if="isLoading"
        class="absolute inset-0 flex items-center justify-center bg-n-alpha-black1"
      >
        <Spinner />
      </div>
    </div>
  </Dialog>
</template>
