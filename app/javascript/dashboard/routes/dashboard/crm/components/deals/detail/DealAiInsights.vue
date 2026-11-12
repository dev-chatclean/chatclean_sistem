<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import Button from 'dashboard/components-next/button/Button.vue';
import DealTemperature from '../DealTemperature.vue';
import { formatDateTime } from './dealTime';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['analyzed', 'createActivity']);

const { t, locale } = useI18n();
const isAnalyzing = ref(false);

const hasTemperature = computed(() =>
  props.deal.ai_features.includes('temperature')
);
const hasNextStep = computed(() =>
  props.deal.ai_features.includes('next_step')
);

const analyze = async () => {
  if (isAnalyzing.value) return;
  isAnalyzing.value = true;
  try {
    const { data } = await CrmDealsAPI.aiAnalyze(props.deal.id);
    emit('analyzed', data);
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(typeof message === 'string' ? message : t('CRM_DEALS.AI.ERROR'));
  } finally {
    isAnalyzing.value = false;
  }
};
</script>

<template>
  <section class="flex flex-col gap-3 p-4 rounded-xl bg-n-alpha-1">
    <div class="flex items-center justify-between gap-2">
      <span class="flex items-center gap-2 text-sm font-medium text-n-slate-12">
        <span class="i-lucide-sparkles size-4 text-n-slate-11" />
        {{ t('CRM_DEALS.AI.TITLE') }}
      </span>
      <Button
        v-tooltip.top="deal.contact ? '' : t('CRM_DEALS.AI.NEEDS_CONVERSATION')"
        :label="t('CRM_DEALS.AI.ANALYZE')"
        icon="i-lucide-refresh-cw"
        slate
        faded
        xs
        :is-loading="isAnalyzing"
        :disabled="!deal.contact"
        @click="analyze"
      />
    </div>
    <div v-if="hasTemperature" class="flex flex-col gap-1">
      <DealTemperature
        v-if="deal.ai_temperature"
        :temperature="deal.ai_temperature"
        class="self-start"
      />
      <span class="text-sm text-n-slate-11">
        {{ deal.ai_temperature_reason || t('CRM_DEALS.AI.NOT_ANALYZED') }}
      </span>
    </div>
    <div v-if="hasNextStep" class="flex flex-col gap-2">
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_DEALS.AI.NEXT_STEP') }}
      </span>
      <span class="text-sm text-n-slate-12">
        {{ deal.ai_next_step || t('CRM_DEALS.AI.NOT_ANALYZED') }}
      </span>
      <Button
        v-if="deal.ai_next_step"
        :label="t('CRM_DEALS.AI.CREATE_ACTIVITY')"
        icon="i-lucide-calendar-plus"
        slate
        ghost
        xs
        class="self-start"
        @click="emit('createActivity', deal.ai_next_step)"
      />
    </div>
    <span v-if="deal.ai_analyzed_at" class="text-label-small text-n-slate-10">
      {{
        t('CRM_DEALS.AI.ANALYZED_AT', {
          date: formatDateTime(deal.ai_analyzed_at, locale),
        })
      }}
    </span>
  </section>
</template>
