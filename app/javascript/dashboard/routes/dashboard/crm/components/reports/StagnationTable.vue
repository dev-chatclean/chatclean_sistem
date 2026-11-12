<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';
import { formatDuration } from '../deals/detail/dealTime';

const props = defineProps({
  stages: { type: Array, required: true },
});

const { t } = useI18n();

const rows = computed(() =>
  props.stages.map(stage => ({ ...stage, key: stage.id }))
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.STAGNATION.TITLE')"
    :description="t('CRM_REPORTS.SALES.STAGNATION.DESCRIPTION')"
  >
    <ReportTable
      :columns="[
        t('CRM_REPORTS.SALES.STAGNATION.STAGE'),
        t('CRM_REPORTS.SALES.STAGNATION.OPEN'),
        t('CRM_REPORTS.SALES.STAGNATION.STALE'),
        t('CRM_REPORTS.SALES.STAGNATION.AVERAGE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-3 py-2.5">
          <span class="flex items-center gap-2 text-n-slate-12">
            <span
              class="rounded-full size-2 shrink-0"
              :style="{ backgroundColor: row.color }"
            />
            {{ row.name }}
          </span>
        </td>
        <td class="px-3 py-2.5 text-end text-n-slate-12">
          {{ row.open_count }}
        </td>
        <td
          class="px-3 py-2.5 text-end"
          :class="row.stale_count ? 'text-n-ruby-11' : 'text-n-slate-12'"
        >
          {{ row.stale_count }}
        </td>
        <td class="px-3 py-2.5 text-end text-n-slate-12">
          {{
            row.average_seconds == null
              ? t('CRM_REPORTS.SALES.NO_DATA')
              : formatDuration(row.average_seconds, t)
          }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
