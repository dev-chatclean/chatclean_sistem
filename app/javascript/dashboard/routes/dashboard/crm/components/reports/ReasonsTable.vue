<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';
import { reasonLabel } from '../../salesReportLabels';

// Ganhos por motivo and Perdas por motivo.
const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  empty: { type: String, required: true },
  reasons: { type: Array, required: true },
  barClass: { type: String, default: 'bg-n-teal-9' },
});

const { t } = useI18n();

const PERCENT = 100;

const total = computed(() =>
  props.reasons.reduce((sum, row) => sum + row.count, 0)
);
const share = row =>
  total.value ? Math.round((row.count / total.value) * PERCENT) : 0;
</script>

<template>
  <ReportCard :title="title" :description="description">
    <p v-if="!reasons.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ empty }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.REASONS.REASON'),
        t('CRM_REPORTS.SALES.REASONS.DEALS'),
        t('CRM_REPORTS.SALES.REASONS.SHARE'),
        t('CRM_REPORTS.SALES.REASONS.VALUE'),
      ]"
      :rows="reasons"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">
          {{ reasonLabel(row.key, t) }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.count }}</td>
        <td class="px-2.5 py-2.5">
          <span class="flex items-center justify-end gap-2 text-n-slate-11">
            <span class="w-24 h-2 rounded-full bg-n-alpha-2">
              <span
                class="block h-full rounded-full"
                :class="barClass"
                :style="{ width: `${share(row)}%` }"
              />
            </span>
            {{ `${share(row)}%` }}
          </span>
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{ formatCurrency(row.value) }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
