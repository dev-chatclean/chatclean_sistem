<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealActivitiesAPI from 'dashboard/api/crm/dealActivities';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ClientMessageEditor from '../../ClientMessageEditor.vue';
import { useClientMessage } from '../../../useClientMessage';
import { formatDateTime } from './dealTime';
import {
  ACTIVITY_PRIORITIES,
  ACTIVITY_RECURRENCES,
  ACTIVITY_TITLE_MAX_LENGTH,
  ACTIVITY_TYPES,
  CLIENT_REMINDER_OPTIONS,
  CLIENT_REMINDER_VARIABLES,
  DEFAULT_ACTIVITY_HOUR,
  DEFAULT_REMIND_BEFORE_MINUTES,
  MAX_ACTIVITY_DURATION_MINUTES,
  MAX_CHECKLIST_ITEMS,
  REMIND_BEFORE_OPTIONS,
} from '../../../constants';

const emit = defineEmits(['saved']);

const MINUTES_IN_HOUR = 60;
const MINUTES_IN_DAY = 1440;
const SELECT_CLASS =
  'reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 disabled:opacity-70';

const { t, locale } = useI18n();
const { isAdmin } = useAdmin();
const { buildMessage, messageError, messagePayload } = useClientMessage();
const currentUser = useMapGetter('getCurrentUser');
const agents = useMapGetter('agents/getAgents');

const dialogRef = ref(null);
const isSaving = ref(false);
const dealId = ref(null);
const dealHasContact = ref(false);
const activity = ref(null);
const showMore = ref(false);
const form = ref({});
const checklistDraft = ref('');

const isRequired = computed(() =>
  Boolean(activity.value?.required_by_stage_name)
);
const isInvalid = computed(() => {
  const title = form.value.title?.trim() || '';
  const duration = form.value.duration_minutes;
  return (
    !title ||
    title.length > ACTIVITY_TITLE_MAX_LENGTH ||
    !form.value.due ||
    (duration !== '' &&
      (Number(duration) <= 0 ||
        Number(duration) > MAX_ACTIVITY_DURATION_MINUTES)) ||
    (form.value.notify_client_before_minutes !== null &&
      Boolean(messageError(form.value.client_message)))
  );
});

const pad = value => String(value).padStart(2, '0');
const toLocalInput = date =>
  `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;

const defaultDue = () => {
  const date = new Date();
  date.setDate(date.getDate() + 1);
  date.setHours(DEFAULT_ACTIVITY_HOUR, 0, 0, 0);
  return toLocalInput(date);
};

const remindLabel = minutes => {
  if (minutes === null) return t('CRM_DEALS.ACTIVITY.REMIND.NONE');
  if (minutes === 0) return t('CRM_DEALS.ACTIVITY.REMIND.AT_TIME');
  if (minutes === MINUTES_IN_HOUR) return t('CRM_DEALS.ACTIVITY.REMIND.HOUR');
  if (minutes === MINUTES_IN_DAY) return t('CRM_DEALS.ACTIVITY.REMIND.DAY');
  return t('CRM_DEALS.ACTIVITY.REMIND.MINUTES', { n: minutes });
};

const open = ({ deal, activity: target = null }) => {
  dealId.value = deal.id;
  dealHasContact.value = Boolean(deal.contact);
  activity.value = target;
  checklistDraft.value = '';
  form.value = target
    ? {
        title: target.title,
        due: toLocalInput(new Date(target.due_at * 1000)),
        activity_type: target.activity_type,
        priority: target.priority,
        assignee_id: target.assignee.id,
        duration_minutes: target.duration_minutes ?? '',
        remind_before_minutes: target.remind_before_minutes,
        description: target.description || '',
        recurrence: target.recurrence,
        checklist: target.checklist.map(item => ({ ...item })),
        notify_client_before_minutes: target.notify_client_before_minutes,
        client_message: buildMessage(target.client_reminder),
      }
    : {
        title: '',
        due: defaultDue(),
        activity_type: ACTIVITY_TYPES[0].value,
        priority: 'medium',
        assignee_id: currentUser.value.id,
        duration_minutes: '',
        remind_before_minutes: DEFAULT_REMIND_BEFORE_MINUTES,
        description: '',
        recurrence: 'never',
        checklist: [],
        notify_client_before_minutes: null,
        client_message: buildMessage(),
      };
  showMore.value = Boolean(target);
  dialogRef.value?.open();
};

const addChecklistItem = () => {
  const title = checklistDraft.value.trim().slice(0, ACTIVITY_TITLE_MAX_LENGTH);
  if (!title || form.value.checklist.length >= MAX_CHECKLIST_ITEMS) return;
  form.value.checklist.push({ title, done: false });
  checklistDraft.value = '';
};

const removeChecklistItem = index => {
  form.value.checklist.splice(index, 1);
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  const payload = {
    title: form.value.title.trim(),
    due_at: new Date(form.value.due).toISOString(),
    activity_type: form.value.activity_type,
    priority: form.value.priority,
    assignee_id: form.value.assignee_id,
    duration_minutes:
      form.value.duration_minutes === ''
        ? null
        : Number(form.value.duration_minutes),
    remind_before_minutes: form.value.remind_before_minutes,
    description: form.value.description.trim() || null,
    recurrence: form.value.recurrence,
    checklist: form.value.checklist,
    notify_client_before_minutes: form.value.notify_client_before_minutes,
  };
  if (form.value.notify_client_before_minutes !== null) {
    payload.client_reminder = {
      ...messagePayload(form.value.client_message),
      time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    };
  }
  try {
    if (activity.value) {
      await CrmDealActivitiesAPI.updateFor(
        dealId.value,
        activity.value.id,
        payload
      );
    } else {
      await CrmDealActivitiesAPI.createFor(dealId.value, payload);
    }
    useAlert(t('CRM_DEALS.API.ACTIVITY_SAVE_SUCCESS'));
    dialogRef.value?.close();
    emit('saved');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      activity ? t('CRM_DEALS.ACTIVITY.EDIT') : t('CRM_DEALS.ACTIVITY.NEW')
    "
    :confirm-button-label="t('CRM_DEALS.ACTIVITY.SAVE')"
    :cancel-button-label="t('CRM_DEALS.ACTIVITY.CANCEL')"
    :disable-confirm-button="isInvalid"
    :is-loading="isSaving"
    overflow-y-auto
    @confirm="save"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.title"
        :label="t('CRM_DEALS.ACTIVITY.TITLE')"
        :placeholder="t('CRM_DEALS.ACTIVITY.TITLE_PLACEHOLDER')"
        :disabled="isRequired"
      />
      <p v-if="isRequired" class="-mt-2 text-label-small text-n-slate-11">
        {{ t('CRM_DEALS.ACTIVITY.REQUIRED_HINT') }}
      </p>
      <label class="flex flex-col gap-1.5">
        <span class="text-label text-n-slate-12">
          {{ t('CRM_DEALS.ACTIVITY.WHEN') }}
        </span>
        <input v-model="form.due" type="datetime-local" :class="SELECT_CLASS" />
      </label>

      <button
        type="button"
        class="flex items-center self-start gap-1.5 text-sm font-medium text-n-blue-11 hover:underline"
        @click="showMore = !showMore"
      >
        <span
          class="size-4"
          :class="showMore ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        />
        {{
          showMore
            ? t('CRM_DEALS.ACTIVITY.LESS_OPTIONS')
            : t('CRM_DEALS.ACTIVITY.MORE_OPTIONS')
        }}
      </button>

      <template v-if="showMore">
        <div class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.TYPE') }}
          </span>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="type in ACTIVITY_TYPES"
              :key="type.value"
              type="button"
              class="flex items-center gap-1.5 h-9 px-3 text-sm rounded-lg outline outline-1 -outline-offset-1"
              :class="
                form.activity_type === type.value
                  ? 'outline-n-blue-9 bg-n-blue-3 text-n-blue-11'
                  : 'outline-n-slate-6 text-n-slate-11 hover:text-n-slate-12'
              "
              @click="form.activity_type = type.value"
            >
              <span class="size-4" :class="type.icon" />
              {{ t(`CRM_DEALS.ACTIVITY.TYPES.${type.value.toUpperCase()}`) }}
            </button>
          </div>
        </div>

        <div class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.PRIORITY') }}
          </span>
          <div class="flex gap-2">
            <button
              v-for="priority in ACTIVITY_PRIORITIES"
              :key="priority"
              type="button"
              class="h-9 px-3 text-sm rounded-lg outline outline-1 -outline-offset-1"
              :class="
                form.priority === priority
                  ? 'outline-n-blue-9 bg-n-blue-3 text-n-blue-11'
                  : 'outline-n-slate-6 text-n-slate-11 hover:text-n-slate-12'
              "
              @click="form.priority = priority"
            >
              {{ t(`CRM_DEALS.ACTIVITY.PRIORITIES.${priority.toUpperCase()}`) }}
            </button>
          </div>
        </div>

        <label class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.ASSIGNEE') }}
          </span>
          <select
            v-model="form.assignee_id"
            :disabled="!isAdmin"
            :class="SELECT_CLASS"
          >
            <option
              v-for="agent in isAdmin ? agents : [currentUser]"
              :key="agent.id"
              :value="agent.id"
            >
              {{ agent.available_name || agent.name }}
            </option>
          </select>
        </label>

        <div class="grid grid-cols-2 gap-3">
          <label class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">
              {{ t('CRM_DEALS.ACTIVITY.DURATION') }}
            </span>
            <input
              v-model="form.duration_minutes"
              type="number"
              min="1"
              :max="MAX_ACTIVITY_DURATION_MINUTES"
              :class="SELECT_CLASS"
            />
          </label>
          <label class="flex flex-col gap-1.5">
            <span class="text-label text-n-slate-12">
              {{ t('CRM_DEALS.ACTIVITY.REMIND_BEFORE') }}
            </span>
            <select v-model="form.remind_before_minutes" :class="SELECT_CLASS">
              <option
                v-for="minutes in REMIND_BEFORE_OPTIONS"
                :key="String(minutes)"
                :value="minutes"
              >
                {{ remindLabel(minutes) }}
              </option>
            </select>
          </label>
        </div>

        <div class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.CLIENT_REMINDER.LABEL') }}
          </span>
          <select
            v-model="form.notify_client_before_minutes"
            :disabled="!dealHasContact"
            :class="SELECT_CLASS"
          >
            <option :value="null">
              {{ t('CRM_DEALS.ACTIVITY.CLIENT_REMINDER.OFF') }}
            </option>
            <option
              v-for="minutes in CLIENT_REMINDER_OPTIONS"
              :key="minutes"
              :value="minutes"
            >
              {{ remindLabel(minutes) }}
            </option>
          </select>
          <span class="text-label-small text-n-slate-11">
            {{
              dealHasContact
                ? t('CRM_DEALS.ACTIVITY.CLIENT_REMINDER.HINT')
                : t('CRM_DEALS.ACTIVITY.CLIENT_REMINDER.NO_CONTACT')
            }}
          </span>
          <span
            v-if="activity?.client_reminder_sent_at"
            class="text-label-small text-n-teal-11"
          >
            {{
              t('CRM_DEALS.ACTIVITY.CLIENT_REMINDER.SENT', {
                date: formatDateTime(activity.client_reminder_sent_at, locale),
              })
            }}
          </span>
        </div>
        <div
          v-if="form.notify_client_before_minutes !== null"
          class="p-3 border rounded-lg border-n-slate-6"
        >
          <ClientMessageEditor
            v-model="form.client_message"
            :variables="CLIENT_REMINDER_VARIABLES"
          />
        </div>

        <label class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.DESCRIPTION') }}
          </span>
          <textarea
            v-model="form.description"
            rows="3"
            :placeholder="t('CRM_DEALS.ACTIVITY.DESCRIPTION_PLACEHOLDER')"
            class="reset-base px-3 py-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 resize-y"
          />
        </label>

        <label class="flex flex-col gap-1.5">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.RECURRENCE') }}
          </span>
          <select
            v-model="form.recurrence"
            :disabled="isRequired"
            :class="SELECT_CLASS"
          >
            <option
              v-for="recurrence in ACTIVITY_RECURRENCES"
              :key="recurrence"
              :value="recurrence"
            >
              {{
                t(`CRM_DEALS.ACTIVITY.RECURRENCES.${recurrence.toUpperCase()}`)
              }}
            </option>
          </select>
        </label>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.ACTIVITY.CHECKLIST') }}
          </span>
          <ul
            v-if="form.checklist.length"
            class="flex flex-col gap-1 p-0 m-0 list-none"
          >
            <li
              v-for="(item, index) in form.checklist"
              :key="index"
              class="flex items-center gap-2 text-sm text-n-slate-12"
            >
              <input v-model="item.done" type="checkbox" class="size-4" />
              <span class="flex-1 truncate">{{ item.title }}</span>
              <button
                type="button"
                class="flex items-center justify-center rounded-md size-7 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-11"
                :aria-label="t('CRM_DEALS.ACTIVITY.CHECKLIST_REMOVE')"
                @click="removeChecklistItem(index)"
              >
                <span class="i-lucide-x size-4" />
              </button>
            </li>
          </ul>
          <div
            v-if="form.checklist.length < MAX_CHECKLIST_ITEMS"
            class="flex gap-2"
          >
            <input
              v-model="checklistDraft"
              type="text"
              :maxlength="ACTIVITY_TITLE_MAX_LENGTH"
              :placeholder="t('CRM_DEALS.ACTIVITY.CHECKLIST_PLACEHOLDER')"
              :class="SELECT_CLASS"
              class="flex-1"
              @keydown.enter.prevent="addChecklistItem"
            />
            <button
              type="button"
              class="flex items-center justify-center rounded-lg size-10 outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-11 hover:text-n-slate-12"
              :aria-label="t('CRM_DEALS.ACTIVITY.CHECKLIST_ADD')"
              @click="addChecklistItem"
            >
              <span class="i-lucide-plus size-4" />
            </button>
          </div>
        </div>
      </template>
    </div>
  </Dialog>
</template>
