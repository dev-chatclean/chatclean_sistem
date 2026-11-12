<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  products: { type: Array, required: true },
});

const { t } = useI18n();

const rows = computed(() =>
  props.products.map(product => ({ ...product, key: product.id }))
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.BLOCKS.NAMES.BY_PRODUCT')"
    :description="t('CRM_REPORTS.SALES.BY_PRODUCT.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.BY_PRODUCT.PRODUCT'),
        t('CRM_REPORTS.SALES.BY_PRODUCT.UNITS'),
        t('CRM_REPORTS.SALES.BY_PRODUCT.REVENUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5 text-n-slate-12">{{ row.name }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.units }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12 whitespace-nowrap">
          {{ formatCurrency(row.revenue) }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
