<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  assignees: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const rows = computed(() =>
  props.assignees
    .map(assignee => ({ ...assignee, key: assignee.id }))
    .sort((a, b) => b.won_value - a.won_value || a.name.localeCompare(b.name))
);

const money = value =>
  value ? formatCurrency(value) : t('CRM_REPORTS.SALES.NO_DATA');

const winRate = row => {
  const closed = row.won_count + row.lost_count;
  return closed
    ? `${Math.round((row.won_count / closed) * PERCENT)}%`
    : t('CRM_REPORTS.SALES.NO_DATA');
};
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.COLLABORATORS.TITLE')"
    :description="t('CRM_REPORTS.SALES.COLLABORATORS.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.COLLABORATORS.ASSIGNEE'),
        t('CRM_REPORTS.SALES.COLLABORATORS.WON'),
        t('CRM_REPORTS.SALES.COLLABORATORS.WON_VALUE'),
        t('CRM_REPORTS.SALES.COLLABORATORS.LOST'),
        t('CRM_REPORTS.SALES.COLLABORATORS.LOST_VALUE'),
        t('CRM_REPORTS.SALES.COLLABORATORS.WIN_RATE'),
        t('CRM_REPORTS.SALES.COLLABORATORS.ACTIVITIES_DONE'),
        t('CRM_REPORTS.SALES.COLLABORATORS.OVERDUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-3 py-2.5">
          <span class="flex items-center gap-2 text-n-slate-12">
            <Avatar
              :name="row.name"
              :src="row.thumbnail"
              :size="22"
              rounded-full
            />
            <span class="truncate">{{ row.name }}</span>
          </span>
        </td>
        <td class="px-3 py-2.5 text-end text-n-teal-11">{{ row.won_count }}</td>
        <td class="px-3 py-2.5 text-end text-n-teal-11 whitespace-nowrap">
          {{ money(row.won_value) }}
        </td>
        <td class="px-3 py-2.5 text-end text-n-slate-12">
          {{ row.lost_count }}
        </td>
        <td class="px-3 py-2.5 text-end text-n-slate-11 whitespace-nowrap">
          {{ money(row.lost_value) }}
        </td>
        <td class="px-3 py-2.5 text-end text-n-slate-12">{{ winRate(row) }}</td>
        <td class="px-3 py-2.5 text-end text-n-slate-12">
          {{ row.activities_done }}
        </td>
        <td
          class="px-3 py-2.5 text-end"
          :class="row.activities_overdue ? 'text-n-ruby-11' : 'text-n-slate-12'"
        >
          {{ row.activities_overdue }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
