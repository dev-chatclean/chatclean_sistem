<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import { formatCurrency } from '../../dealHelpers';

// Distribuição de ganhos por origem: each item's share of the total, as bars.
const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  rows: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;
// The ChatClean brand turns n-blue into its green, so it comes last, away from teal.
const BAR_COLORS = [
  'bg-n-teal-9',
  'bg-n-iris-9',
  'bg-n-amber-9',
  'bg-n-ruby-9',
  'bg-n-slate-9',
  'bg-n-blue-9',
];

const total = computed(() =>
  props.rows.reduce((sum, row) => sum + row.value, 0)
);
const sorted = computed(() =>
  [...props.rows].sort((a, b) => b.value - a.value)
);

const share = row => (total.value ? (row.value / total.value) * PERCENT : 0);
</script>

<template>
  <ReportCard :title="title" :description="description">
    <p v-if="!total" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <div v-else class="flex flex-col gap-3">
      <div
        v-for="(row, index) in sorted"
        :key="row.key"
        class="flex flex-col gap-1 text-sm"
      >
        <div class="flex items-center justify-between gap-3">
          <span class="truncate text-n-slate-12">{{ row.label }}</span>
          <span class="shrink-0 text-n-slate-11">
            {{ `${Math.round(share(row))}% · ${formatCurrency(row.value)}` }}
          </span>
        </div>
        <div class="h-2 rounded-full bg-n-alpha-2">
          <div
            class="h-full rounded-full"
            :class="BAR_COLORS[index % BAR_COLORS.length]"
            :style="{ width: `${share(row)}%` }"
          />
        </div>
      </div>
    </div>
  </ReportCard>
</template>
