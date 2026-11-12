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

const rows = computed(() =>
  props.assignees
    .filter(assignee => assignee.deals || assignee.won_count)
    .map(assignee => ({ ...assignee, key: assignee.id }))
    .sort((a, b) => b.won_value - a.won_value || b.deals - a.deals)
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.BY_ASSIGNEE.TITLE')"
    :description="t('CRM_REPORTS.SALES.BY_ASSIGNEE.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.BY_ASSIGNEE.EMPTY') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.BY_ASSIGNEE.ASSIGNEE'),
        t('CRM_REPORTS.SALES.BY_ASSIGNEE.DEALS'),
        t('CRM_REPORTS.SALES.BY_ASSIGNEE.WON'),
        t('CRM_REPORTS.SALES.BY_ASSIGNEE.VALUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">{{ row.name }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.deals }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">
          {{ row.won_count }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{
            row.won_value
              ? formatCurrency(row.won_value)
              : t('CRM_REPORTS.SALES.NO_DATA')
          }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
