<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  stages: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const total = computed(() =>
  props.stages.reduce((sum, stage) => sum + stage.lost, 0)
);
const rows = computed(() =>
  props.stages.map(stage => ({ ...stage, key: stage.id }))
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.BLOCKS.NAMES.WHERE_LOST')"
    :description="t('CRM_REPORTS.SALES.WHERE_LOST.DESCRIPTION')"
  >
    <p v-if="!total" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.WHERE_LOST.EMPTY') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.SALES.WHERE_LOST.STAGE'),
        t('CRM_REPORTS.SALES.WHERE_LOST.LOST'),
        t('CRM_REPORTS.SALES.WHERE_LOST.SHARE'),
        t('CRM_REPORTS.SALES.WHERE_LOST.VALUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5">
          <span class="flex items-center gap-2 text-n-slate-12">
            <span
              class="rounded-full size-2 shrink-0"
              :style="{ backgroundColor: row.color }"
            />
            {{ row.name }}
          </span>
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">{{ row.lost }}</td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-11">
          {{ `${Math.round((row.lost / total) * PERCENT)}%` }}
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
