<script setup>
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import PipelineStageBars from './PipelineStageBars.vue';

defineProps({
  stages: { type: Array, required: true },
  pipelineName: { type: String, default: '' },
  title: { type: String, default: '' },
});

const { t } = useI18n();
</script>

<template>
  <ReportCard
    :title="title || t('CRM_REPORTS.SALES.PIPELINE.TITLE')"
    :description="t('CRM_REPORTS.SALES.PIPELINE.DESCRIPTION')"
  >
    <template v-if="pipelineName" #actions>
      <span class="text-label-small text-n-slate-11 shrink-0">
        {{ pipelineName }}
      </span>
    </template>
    <PipelineStageBars v-if="stages.length" :stages="stages" />
    <p v-else class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.PIPELINE.NO_PIPELINE') }}
    </p>
  </ReportCard>
</template>
