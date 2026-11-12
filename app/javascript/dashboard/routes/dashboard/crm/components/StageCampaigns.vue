<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn, useIntervalFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmStageCampaignsAPI from 'dashboard/api/crm/stageCampaigns';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ClientMessageEditor from './ClientMessageEditor.vue';
import { useClientMessage } from '../useClientMessage';
import { formatDateTime } from './deals/detail/dealTime';
import {
  CAMPAIGN_COUNT_STATUSES,
  CAMPAIGN_MAX_STALE_DAYS,
  CAMPAIGN_NAME_MAX_LENGTH,
  CAMPAIGN_POLL_INTERVAL_MS,
  CAMPAIGN_PREVIEW_DEBOUNCE_MS,
  IMPULSE_VARIABLES,
} from '../constants';

const props = defineProps({
  pipeline: { type: Object, required: true },
  stage: { type: Object, required: true },
});

const STATUS_CLASSES = {
  running: 'text-n-blue-11',
  completed: 'text-n-teal-11',
  canceled: 'text-n-slate-11',
};
const SELECT_CLASS =
  'reset-base h-10 ps-3 pe-6 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12';

const { t, locale } = useI18n();
const { buildMessage, messageError, messagePayload } = useClientMessage();
const agents = useMapGetter('agents/getAgents');
const { run: runPreview, isPending: isPreviewLoading } = useAbortableRequest();

const campaigns = ref([]);
const isLoading = ref(false);
const isSending = ref(false);
const form = ref(null);
const preview = ref(null);
const pendingCancelId = ref(null);

const isClosingStage = computed(() =>
  ['won', 'lost'].includes(props.stage.stage_type)
);

const fetchCampaigns = async () => {
  const { data } = await CrmStageCampaignsAPI.list(
    props.pipeline.id,
    props.stage.id
  );
  campaigns.value = data.payload;
};

const loadCampaigns = async () => {
  isLoading.value = true;
  try {
    await fetchCampaigns();
  } finally {
    isLoading.value = false;
  }
};

const { pause, resume } = useIntervalFn(
  fetchCampaigns,
  CAMPAIGN_POLL_INTERVAL_MS,
  { immediate: false }
);

watch(
  () => !form.value && campaigns.value.some(item => item.status === 'running'),
  shouldPoll => (shouldPoll ? resume() : pause())
);

onMounted(loadCampaigns);

const staleDaysError = computed(() => {
  const value = form.value?.staleDays;
  if (value === '' || value === null || value === undefined) return '';
  const days = Number(value);
  return Number.isInteger(days) && days >= 1 && days <= CAMPAIGN_MAX_STALE_DAYS
    ? ''
    : t('CRM_PIPELINES.CAMPAIGNS.ERRORS.STALE_DAYS', {
        max: CAMPAIGN_MAX_STALE_DAYS,
      });
});

const nameError = computed(() =>
  form.value?.name.trim().length > CAMPAIGN_NAME_MAX_LENGTH
    ? t('CRM_PIPELINES.CAMPAIGNS.ERRORS.NAME', {
        max: CAMPAIGN_NAME_MAX_LENGTH,
      })
    : ''
);

const filtersPayload = () => {
  const filters = {};
  if (form.value.assigneeId)
    filters.assignee_id = Number(form.value.assigneeId);
  if (form.value.staleDays !== '') {
    filters.stale_days = Number(form.value.staleDays);
  }
  return filters;
};

const loadPreview = useDebounceFn(async () => {
  if (!form.value || staleDaysError.value) return;
  const response = await runPreview(signal =>
    CrmStageCampaignsAPI.preview(
      props.pipeline.id,
      props.stage.id,
      filtersPayload(),
      { signal }
    )
  );
  if (response) preview.value = response.data;
}, CAMPAIGN_PREVIEW_DEBOUNCE_MS);

watch(
  () => form.value && [form.value.assigneeId, form.value.staleDays],
  () => {
    if (form.value) loadPreview();
  }
);

const startNew = () => {
  preview.value = null;
  form.value = {
    name: '',
    assigneeId: '',
    staleDays: '',
    message: buildMessage({ message_type: 'template' }),
  };
};

const closeForm = () => {
  form.value = null;
};

const canSend = computed(
  () =>
    Boolean(form.value?.name.trim()) &&
    !nameError.value &&
    !staleDaysError.value &&
    !messageError(form.value.message) &&
    !isPreviewLoading.value &&
    preview.value?.with_contact > 0
);

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const send = async () => {
  if (isSending.value || !canSend.value) return;
  isSending.value = true;
  try {
    await CrmStageCampaignsAPI.createCampaign(
      props.pipeline.id,
      props.stage.id,
      {
        name: form.value.name.trim(),
        filters: filtersPayload(),
        ...messagePayload(form.value.message),
      }
    );
    useAlert(t('CRM_PIPELINES.CAMPAIGNS.API.SEND_SUCCESS'));
    form.value = null;
    await loadCampaigns();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  } finally {
    isSending.value = false;
  }
};

const cancelPending = async campaign => {
  if (pendingCancelId.value !== campaign.id) {
    pendingCancelId.value = campaign.id;
    return;
  }
  pendingCancelId.value = null;
  try {
    await CrmStageCampaignsAPI.cancelPending(
      props.pipeline.id,
      props.stage.id,
      campaign.id
    );
    useAlert(t('CRM_PIPELINES.CAMPAIGNS.API.CANCEL_SUCCESS'));
    await fetchCampaigns();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  }
};

const countsText = campaign =>
  CAMPAIGN_COUNT_STATUSES.filter(status => campaign.counts[status])
    .map(status =>
      t(
        `CRM_PIPELINES.CAMPAIGNS.COUNTS.${status.toUpperCase()}`,
        { count: campaign.counts[status] },
        campaign.counts[status]
      )
    )
    .join(' · ');

const failureReasons = campaign =>
  Object.entries(campaign.failure_reasons).map(
    ([reason, count]) =>
      `${t(`CRM_DEALS.IMPULSES.REASONS.${reason.toUpperCase()}`)}: ${count}`
  );

defineExpose({ form, canSend, isSending, startNew, closeForm, send });
</script>

<template>
  <div v-if="!form" class="flex flex-col gap-3">
    <span v-if="isLoading" class="text-sm text-n-slate-11">
      {{ t('CRM_PIPELINES.CAMPAIGNS.LOADING') }}
    </span>
    <div
      v-else-if="!campaigns.length"
      class="px-3 py-2.5 text-sm border rounded-lg border-n-slate-6 text-n-slate-11"
    >
      {{ t('CRM_PIPELINES.CAMPAIGNS.EMPTY') }}
    </div>
    <div
      v-for="campaign in campaigns"
      :key="campaign.id"
      class="flex items-start justify-between gap-3 px-3 py-2.5 border rounded-lg border-n-slate-6"
    >
      <div class="flex flex-col min-w-0 gap-0.5">
        <span class="flex items-center gap-2 text-sm text-n-slate-12">
          <span class="font-medium truncate">{{ campaign.name }}</span>
          <span
            class="text-label-small shrink-0"
            :class="STATUS_CLASSES[campaign.status]"
          >
            {{
              t(
                `CRM_PIPELINES.CAMPAIGNS.STATUS.${campaign.status.toUpperCase()}`
              )
            }}
          </span>
        </span>
        <span class="text-label-small text-n-slate-11">
          {{
            t('CRM_PIPELINES.CAMPAIGNS.BY', {
              user: campaign.created_by_name,
              date: formatDateTime(campaign.created_at, locale),
            })
          }}
        </span>
        <span class="text-label-small text-n-slate-12">
          {{ countsText(campaign) }}
        </span>
        <span
          v-for="reason in failureReasons(campaign)"
          :key="reason"
          class="text-label-small text-n-ruby-11"
        >
          {{ reason }}
        </span>
      </div>
      <Button
        v-if="campaign.status === 'running' && campaign.counts.scheduled"
        :label="
          pendingCancelId === campaign.id
            ? t('CRM_PIPELINES.CAMPAIGNS.CONFIRM_CANCEL')
            : t('CRM_PIPELINES.CAMPAIGNS.CANCEL_PENDING')
        "
        ruby
        faded
        xs
        class="shrink-0"
        @click="cancelPending(campaign)"
      />
    </div>
  </div>

  <div v-else class="flex flex-col gap-5">
    <Input
      v-model="form.name"
      :label="t('CRM_PIPELINES.CAMPAIGNS.NAME.LABEL')"
      :placeholder="t('CRM_PIPELINES.CAMPAIGNS.NAME.PLACEHOLDER')"
      :message="nameError"
      :message-type="nameError ? 'error' : 'info'"
      autofocus
    />

    <div class="flex flex-col gap-3 p-3 border rounded-lg border-n-slate-6">
      <span class="text-label text-n-slate-12">
        {{ t('CRM_PIPELINES.CAMPAIGNS.FILTERS.TITLE') }}
      </span>
      <div class="flex flex-wrap items-start gap-3">
        <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
          {{ t('CRM_PIPELINES.CAMPAIGNS.FILTERS.ASSIGNEE') }}
          <select v-model="form.assigneeId" :class="SELECT_CLASS">
            <option value="">
              {{ t('CRM_PIPELINES.CAMPAIGNS.FILTERS.ALL_ASSIGNEES') }}
            </option>
            <option v-for="agent in agents" :key="agent.id" :value="agent.id">
              {{ agent.name }}
            </option>
          </select>
        </label>
        <Input
          v-model="form.staleDays"
          type="number"
          min="1"
          :max="CAMPAIGN_MAX_STALE_DAYS"
          class="flex-1 min-w-64"
          :label="t('CRM_PIPELINES.CAMPAIGNS.FILTERS.STALE_DAYS')"
          :message="
            staleDaysError || t('CRM_PIPELINES.CAMPAIGNS.FILTERS.STALE_HINT')
          "
          :message-type="staleDaysError ? 'error' : 'info'"
        />
      </div>

      <div
        class="flex flex-col gap-1 px-3 py-2.5 text-sm rounded-lg bg-n-alpha-black2"
      >
        <span v-if="isPreviewLoading || !preview" class="text-n-slate-11">
          {{ t('CRM_PIPELINES.CAMPAIGNS.PREVIEW.LOADING') }}
        </span>
        <template v-else>
          <span v-if="preview.with_contact" class="text-n-slate-12">
            {{
              t(
                'CRM_PIPELINES.CAMPAIGNS.PREVIEW.SUMMARY',
                { count: preview.with_contact },
                preview.with_contact
              )
            }}
          </span>
          <span v-else class="text-n-ruby-11">
            {{ t('CRM_PIPELINES.CAMPAIGNS.PREVIEW.NONE') }}
          </span>
          <span v-if="preview.without_contact" class="text-n-slate-11">
            {{
              t(
                'CRM_PIPELINES.CAMPAIGNS.PREVIEW.WITHOUT_CONTACT',
                { count: preview.without_contact },
                preview.without_contact
              )
            }}
          </span>
          <span v-if="preview.in_running_campaign" class="text-n-slate-11">
            {{
              t(
                'CRM_PIPELINES.CAMPAIGNS.PREVIEW.IN_RUNNING_CAMPAIGN',
                { count: preview.in_running_campaign },
                preview.in_running_campaign
              )
            }}
          </span>
        </template>
        <span v-if="isClosingStage" class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.CAMPAIGNS.PREVIEW.CLOSED_HINT') }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.CAMPAIGNS.PREVIEW.INTERVAL') }}
        </span>
      </div>
    </div>

    <ClientMessageEditor
      v-model="form.message"
      :variables="IMPULSE_VARIABLES"
    />
  </div>
</template>
