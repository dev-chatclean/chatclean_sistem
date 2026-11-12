<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  companies: { type: Array, required: true },
});

const { t } = useI18n();

const rows = computed(() =>
  props.companies.map(company => ({ ...company, key: company.id }))
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.BLOCKS.NAMES.BY_COMPANY')"
    :description="t('CRM_REPORTS.SALES.BY_COMPANY.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.BY_COMPANY.EMPTY') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.BY_COMPANY.COMPANY'),
        t('CRM_REPORTS.SALES.BY_COMPANY.WON'),
        t('CRM_REPORTS.SALES.BY_COMPANY.OPEN'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">{{ row.name }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-teal-11 whitespace-nowrap">
          {{
            row.won_value
              ? formatCurrency(row.won_value)
              : t('CRM_REPORTS.SALES.NO_DATA')
          }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{
            row.open_count
              ? t(
                  'CRM_REPORTS.SALES.BY_COMPANY.OPEN_VALUE',
                  {
                    count: row.open_count,
                    value: formatCurrency(row.open_value),
                  },
                  row.open_count
                )
              : t('CRM_REPORTS.SALES.NO_DATA')
          }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
