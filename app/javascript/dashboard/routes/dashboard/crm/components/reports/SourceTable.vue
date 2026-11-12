<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

// Por origem and Por canal: the leads created in the period and how many of the closed ones became a sale.
const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  firstColumn: { type: String, required: true },
  rows: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const sorted = computed(() =>
  [...props.rows].sort((a, b) => b.leads - a.leads)
);

const conversion = row => {
  const closed = row.won + row.lost;
  return closed
    ? `${Math.round((row.won / closed) * PERCENT)}%`
    : t('CRM_REPORTS.SALES.SOURCES.NO_CLOSED');
};
</script>

<template>
  <ReportCard :title="title" :description="description">
    <p v-if="!sorted.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        firstColumn,
        t('CRM_REPORTS.SALES.SOURCES.LEADS'),
        t('CRM_REPORTS.SALES.SOURCES.WON'),
        t('CRM_REPORTS.SALES.SOURCES.LOST'),
        t('CRM_REPORTS.SALES.SOURCES.CONVERSION'),
        t('CRM_REPORTS.SALES.SOURCES.VALUE'),
      ]"
      :rows="sorted"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">{{ row.label }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.leads }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.won }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.lost }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-11">
          {{ conversion(row) }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{
            row.value
              ? formatCurrency(row.value)
              : t('CRM_REPORTS.SALES.NO_DATA')
          }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
