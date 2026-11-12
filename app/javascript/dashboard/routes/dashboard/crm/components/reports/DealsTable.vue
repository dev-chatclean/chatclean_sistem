<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';
import { formatDuration, formatShortDateTime } from '../deals/detail/dealTime';
import { reasonLabel } from '../../salesReportLabels';

// Negócios ganhos (products and how long it took) and Negócios perdidos (stage, reason and note).
const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  empty: { type: String, required: true },
  deals: { type: Array, required: true },
  lost: { type: Boolean, default: false },
  limit: { type: Number, required: true },
});

const { t, locale } = useI18n();

const rows = computed(() =>
  props.deals.map(deal => ({ ...deal, key: deal.id }))
);

const columns = computed(() => [
  t('CRM_REPORTS.SALES.DEALS.DEAL'),
  t('CRM_REPORTS.SALES.DEALS.ASSIGNEE'),
  ...(props.lost
    ? [
        t('CRM_REPORTS.SALES.DEALS.STAGE'),
        t('CRM_REPORTS.SALES.DEALS.REASON'),
        t('CRM_REPORTS.SALES.DEALS.NOTE'),
      ]
    : [
        t('CRM_REPORTS.SALES.DEALS.PRODUCTS'),
        t('CRM_REPORTS.SALES.DEALS.CYCLE'),
      ]),
  t('CRM_REPORTS.SALES.DEALS.VALUE'),
  t('CRM_REPORTS.SALES.DEALS.CLOSED_AT'),
]);

const reasonText = deal => (deal.reason ? reasonLabel(deal.reason, t) : '—');
</script>

<template>
  <ReportCard :title="title" :description="description">
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ empty }}
    </p>
    <template v-else>
      <ReportTable :columns="columns" :rows="rows">
        <template #row="{ row }">
          <td class="px-2.5 py-2.5 text-n-slate-12">
            <span class="text-n-slate-11">
              {{ t('CRM_DEALS.NUMBER', { number: row.number }) }}
            </span>
            {{ row.name }}
          </td>
          <td class="px-2.5 py-2.5 text-end text-n-slate-12">
            {{ row.assignee }}
          </td>
          <template v-if="lost">
            <td class="px-2.5 py-2.5 text-end text-n-slate-12">
              {{ row.lost_stage || '—' }}
            </td>
            <td class="px-2.5 py-2.5 text-end text-n-slate-12">
              {{ reasonText(row) }}
            </td>
            <td
              class="px-2.5 py-2.5 text-end text-n-slate-11 max-w-56 truncate"
            >
              {{ row.note || '—' }}
            </td>
          </template>
          <template v-else>
            <td
              class="px-2.5 py-2.5 text-end text-n-slate-11 max-w-56 truncate"
            >
              {{ row.products.join(', ') || '—' }}
            </td>
            <td
              class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap"
            >
              {{ formatDuration(row.cycle_seconds, t) }}
            </td>
          </template>
          <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
            {{ formatCurrency(row.value) }}
          </td>
          <td class="px-2.5 py-2.5 text-end text-n-slate-11 whitespace-nowrap">
            {{ formatShortDateTime(row.closed_at, locale) }}
          </td>
        </template>
      </ReportTable>
      <span
        v-if="rows.length >= limit"
        class="text-label-small text-n-slate-11"
      >
        {{ t('CRM_REPORTS.SALES.DEALS.LIMIT', { count: limit }) }}
      </span>
    </template>
  </ReportCard>
</template>
