<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealImpulseExecutionsAPI from 'dashboard/api/crm/dealImpulseExecutions';
import Button from 'dashboard/components-next/button/Button.vue';
import { formatDateTime } from './dealTime';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['changed']);

const STATUS_CLASSES = {
  scheduled: 'bg-n-blue-3 text-n-blue-11',
  sent: 'bg-n-teal-3 text-n-teal-11',
  canceled: 'bg-n-slate-3 text-n-slate-11',
  failed: 'bg-n-ruby-3 text-n-ruby-11',
};

const { t, locale } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');
const cancelingId = ref(null);

const canCancel = execution =>
  execution.status === 'scheduled' &&
  (isAdmin.value || props.deal.assignee.id === currentUser.value.id);

const reasonText = reason =>
  t(`CRM_DEALS.IMPULSES.REASONS.${reason.toUpperCase()}`);

const executionDetails = execution =>
  [
    t(`CRM_DEALS.IMPULSES.TYPE.${execution.message_type.toUpperCase()}`),
    formatDateTime(
      execution.executed_at || execution.scheduled_at,
      locale.value
    ),
    execution.failure_reason && reasonText(execution.failure_reason),
  ]
    .filter(Boolean)
    .join(' · ');

const cancel = async execution => {
  cancelingId.value = execution.id;
  try {
    await CrmDealImpulseExecutionsAPI.cancel(props.deal.id, execution.id);
    emit('changed');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    cancelingId.value = null;
  }
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <span class="text-sm text-n-slate-11">
      {{ t('CRM_DEALS.IMPULSES.HINT') }}
    </span>
    <div
      v-if="!deal.impulse_executions.length"
      class="px-3 py-2.5 text-sm border rounded-lg border-n-slate-6 text-n-slate-11"
    >
      {{ t('CRM_DEALS.IMPULSES.EMPTY') }}
    </div>
    <div
      v-for="execution in deal.impulse_executions"
      :key="execution.id"
      class="flex items-center justify-between gap-3 px-3 py-2.5 border rounded-lg border-n-slate-6"
    >
      <div class="flex flex-col min-w-0 gap-0.5">
        <span class="flex items-center gap-2 text-sm text-n-slate-12">
          <span class="i-lucide-send size-4 text-n-slate-10 shrink-0" />
          <span class="truncate">
            {{
              t('CRM_DEALS.IMPULSES.STEP', {
                impulse: execution.impulse_name,
                step: execution.step_position,
              })
            }}
          </span>
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ executionDetails(execution) }}
        </span>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <span
          class="px-2 py-0.5 text-label-small rounded-md"
          :class="STATUS_CLASSES[execution.status]"
        >
          {{ t(`CRM_DEALS.IMPULSES.STATUS.${execution.status.toUpperCase()}`) }}
        </span>
        <Button
          v-if="canCancel(execution)"
          :label="t('CRM_DEALS.IMPULSES.CANCEL')"
          slate
          faded
          xs
          :is-loading="cancelingId === execution.id"
          @click="cancel(execution)"
        />
      </div>
    </div>
  </div>
</template>
