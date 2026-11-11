<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealActivitiesAPI from 'dashboard/api/crm/dealActivities';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { ACTIVITY_TYPES } from '../../../constants';
import { formatDateTime } from './dealTime';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['new', 'edit', 'changed']);

const PRIORITY_CLASS = {
  low: 'bg-n-slate-3 text-n-slate-11',
  medium: 'bg-n-amber-3 text-n-amber-11',
  high: 'bg-n-ruby-3 text-n-ruby-11',
};
const TYPE_ICONS = Object.fromEntries(
  ACTIVITY_TYPES.map(type => [type.value, type.icon])
);

const { t, locale } = useI18n();

const deleteDialogRef = ref(null);
const pendingDelete = ref(null);
const expandedId = ref(null);
const busyId = ref(null);

const pending = computed(() =>
  props.deal.activities.filter(activity => !activity.completed_at)
);
const done = computed(() =>
  props.deal.activities
    .filter(activity => activity.completed_at)
    .sort((a, b) => b.completed_at - a.completed_at)
);
const sections = computed(() =>
  [
    { key: 'PENDING', items: pending.value },
    { key: 'DONE', items: done.value },
  ].filter(section => section.items.length)
);

const isOverdue = activity =>
  !activity.completed_at && activity.due_at * 1000 < Date.now();

const checklistDone = activity =>
  activity.checklist.filter(item => item.done).length;

const save = async (activity, changes) => {
  busyId.value = activity.id;
  try {
    await CrmDealActivitiesAPI.updateFor(props.deal.id, activity.id, changes);
    emit('changed');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    busyId.value = null;
  }
};

const toggleDone = activity =>
  save(activity, { completed: !activity.completed_at });

const toggleChecklistItem = (activity, index) =>
  save(activity, {
    checklist: activity.checklist.map((item, i) =>
      i === index ? { ...item, done: !item.done } : item
    ),
  });

const askDelete = activity => {
  pendingDelete.value = activity;
  deleteDialogRef.value?.open();
};

const confirmDelete = async () => {
  const activity = pendingDelete.value;
  try {
    await CrmDealActivitiesAPI.deleteFor(props.deal.id, activity.id);
    useAlert(t('CRM_DEALS.API.ACTIVITY_DELETE_SUCCESS'));
    deleteDialogRef.value?.close();
    emit('changed');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  }
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex justify-end">
      <button
        type="button"
        class="flex items-center gap-2 h-10 px-4 text-sm font-medium rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1"
        @click="emit('new')"
      >
        <span class="i-lucide-plus size-4" />
        {{ t('CRM_DEALS.ACTIVITY.ADD') }}
      </button>
    </div>

    <p
      v-if="!sections.length"
      class="py-10 text-base text-center text-n-slate-11"
    >
      {{ t('CRM_DEALS.ACTIVITY.EMPTY') }}
    </p>

    <section
      v-for="section in sections"
      :key="section.key"
      class="flex flex-col gap-3"
    >
      <h3 class="m-0 text-sm font-medium text-n-slate-11">
        {{ t(`CRM_DEALS.ACTIVITY.${section.key}`) }} ·
        {{ section.items.length }}
      </h3>
      <ul class="flex flex-col gap-2 p-0 m-0 list-none">
        <li
          v-for="activity in section.items"
          :key="activity.id"
          class="flex flex-col gap-3 p-4 border rounded-xl border-n-weak bg-n-solid-2"
          :class="{ 'opacity-50 pointer-events-none': busyId === activity.id }"
        >
          <div class="flex items-start gap-3">
            <button
              type="button"
              class="flex items-center justify-center mt-0.5 rounded-full size-5 shrink-0 outline outline-2 -outline-offset-2"
              :class="
                activity.completed_at
                  ? 'outline-n-teal-9 bg-n-teal-9 text-white'
                  : 'outline-n-slate-8 hover:outline-n-teal-9'
              "
              :aria-label="
                activity.completed_at
                  ? t('CRM_DEALS.ACTIVITY.MARK_PENDING')
                  : t('CRM_DEALS.ACTIVITY.MARK_DONE')
              "
              @click="toggleDone(activity)"
            >
              <span
                v-if="activity.completed_at"
                class="i-lucide-check size-3.5"
              />
            </button>
            <div class="flex flex-col flex-1 min-w-0 gap-1.5">
              <button
                type="button"
                class="flex items-center gap-2 text-start min-w-0"
                @click="
                  expandedId = expandedId === activity.id ? null : activity.id
                "
              >
                <span
                  class="size-4 shrink-0 text-n-slate-11"
                  :class="TYPE_ICONS[activity.activity_type]"
                />
                <span
                  class="text-base font-medium truncate text-n-slate-12"
                  :class="{
                    'line-through text-n-slate-11': activity.completed_at,
                  }"
                >
                  {{ activity.title }}
                </span>
              </button>
              <div
                class="flex flex-wrap items-center gap-x-3 gap-y-1 text-label-small text-n-slate-11"
              >
                <span
                  class="flex items-center gap-1"
                  :class="{ 'text-n-ruby-11 font-medium': isOverdue(activity) }"
                >
                  <span class="i-lucide-calendar-clock size-3.5" />
                  {{ formatDateTime(activity.due_at, locale) }}
                  <template v-if="isOverdue(activity)">
                    · {{ t('CRM_DEALS.ACTIVITY.OVERDUE') }}
                  </template>
                </span>
                <span
                  class="px-1.5 py-0.5 rounded-md"
                  :class="PRIORITY_CLASS[activity.priority]"
                >
                  {{
                    t(
                      `CRM_DEALS.ACTIVITY.PRIORITIES.${activity.priority.toUpperCase()}`
                    )
                  }}
                </span>
                <span class="flex items-center gap-1">
                  <span class="i-lucide-user size-3.5" />
                  {{ activity.assignee.name }}
                </span>
                <span
                  v-if="activity.duration_minutes"
                  class="flex items-center gap-1"
                >
                  <span class="i-lucide-timer size-3.5" />
                  {{
                    t('CRM_DEALS.ACTIVITY.DURATION_VALUE', {
                      n: activity.duration_minutes,
                    })
                  }}
                </span>
                <span
                  v-if="activity.recurrence !== 'never'"
                  class="flex items-center gap-1"
                >
                  <span class="i-lucide-repeat size-3.5" />
                  {{
                    t(
                      `CRM_DEALS.ACTIVITY.RECURRENCES.${activity.recurrence.toUpperCase()}`
                    )
                  }}
                </span>
                <span
                  v-if="activity.checklist.length"
                  class="flex items-center gap-1"
                >
                  <span class="i-lucide-list-checks size-3.5" />
                  {{
                    t('CRM_DEALS.ACTIVITY.CHECKLIST_PROGRESS', {
                      done: checklistDone(activity),
                      total: activity.checklist.length,
                    })
                  }}
                </span>
                <span
                  v-if="activity.required_by_stage_name"
                  class="flex items-center gap-1 px-1.5 py-0.5 rounded-md bg-n-blue-3 text-n-blue-11"
                >
                  <span class="i-lucide-lock size-3" />
                  {{
                    t('CRM_DEALS.ACTIVITY.REQUIRED', {
                      stage: activity.required_by_stage_name,
                    })
                  }}
                </span>
              </div>
            </div>
            <div class="flex items-center gap-1 shrink-0">
              <button
                type="button"
                class="flex items-center justify-center rounded-lg size-8 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
                :aria-label="t('CRM_DEALS.ACTIVITY.EDIT_ACTION')"
                @click="emit('edit', activity)"
              >
                <span class="i-lucide-pencil size-4" />
              </button>
              <button
                v-if="!activity.required_by_stage_name"
                type="button"
                class="flex items-center justify-center rounded-lg size-8 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-11"
                :aria-label="t('CRM_DEALS.ACTIVITY.DELETE_ACTION')"
                @click="askDelete(activity)"
              >
                <span class="i-lucide-trash-2 size-4" />
              </button>
            </div>
          </div>
          <div
            v-if="
              expandedId === activity.id &&
              (activity.description || activity.checklist.length)
            "
            class="flex flex-col gap-3 ps-8"
          >
            <p
              v-if="activity.description"
              class="m-0 text-sm whitespace-pre-line text-n-slate-12"
            >
              {{ activity.description }}
            </p>
            <ul
              v-if="activity.checklist.length"
              class="flex flex-col gap-1.5 p-0 m-0 list-none"
            >
              <li
                v-for="(item, index) in activity.checklist"
                :key="index"
                class="flex items-center gap-2 text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  class="size-4"
                  :checked="item.done"
                  @change="toggleChecklistItem(activity, index)"
                />
                <span :class="{ 'line-through text-n-slate-11': item.done }">
                  {{ item.title }}
                </span>
              </li>
            </ul>
          </div>
        </li>
      </ul>
    </section>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('CRM_DEALS.ACTIVITY.DELETE_ACTION')"
      :description="
        t('CRM_DEALS.ACTIVITY.DELETE_CONFIRM', {
          title: pendingDelete?.title || '',
        })
      "
      :confirm-button-label="t('CRM_DEALS.ACTIVITY.DELETE_ACTION')"
      :cancel-button-label="t('CRM_DEALS.ACTIVITY.CANCEL')"
      @confirm="confirmDelete"
    />
  </div>
</template>
