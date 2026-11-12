<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  assignees: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const lossRate = row => row.lost_count / (row.won_count + row.lost_count);

const rows = computed(() =>
  props.assignees
    .filter(assignee => assignee.lost_count)
    .map(assignee => ({ ...assignee, key: assignee.id }))
    .sort((a, b) => lossRate(b) - lossRate(a))
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.BLOCKS.NAMES.LOST_BY_ASSIGNEE')"
    :description="t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.EMPTY') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.ASSIGNEE'),
        t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.LOST'),
        t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.CLOSED'),
        t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.RATE'),
        t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.VALUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">{{ row.name }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">
          {{ row.lost_count }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">
          {{ row.won_count + row.lost_count }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-ruby-11">
          {{ `${Math.round(lossRate(row) * PERCENT)}%` }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{ formatCurrency(row.lost_value) }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
