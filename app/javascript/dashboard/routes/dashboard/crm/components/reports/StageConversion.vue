<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ReportCard from './ReportCard.vue';
import ReportTable from './ReportTable.vue';

const props = defineProps({
  stages: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const passRate = stage =>
  stage.moved_on == null || !stage.reached
    ? null
    : stage.moved_on / stage.reached;

// "maior queda": the stage that keeps the smallest share of the deals that reached it.
const biggestDropId = computed(() => {
  const rated = props.stages.filter(stage => passRate(stage) != null);
  if (!rated.length) return null;
  return rated.reduce((low, stage) =>
    passRate(stage) < passRate(low) ? stage : low
  ).id;
});

const rows = computed(() =>
  props.stages.map(stage => ({ ...stage, key: stage.id }))
);

const movedOnText = stage => {
  if (stage.moved_on == null) return t('CRM_REPORTS.SALES.CONVERSION.LAST');
  if (!stage.reached) return t('CRM_REPORTS.SALES.CONVERSION.NO_DATA');
  return t('CRM_REPORTS.SALES.CONVERSION.MOVED_ON_VALUE', {
    moved: stage.moved_on,
    reached: stage.reached,
    percent: Math.round(passRate(stage) * PERCENT),
  });
};
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.CONVERSION.TITLE')"
    :description="t('CRM_REPORTS.SALES.CONVERSION.DESCRIPTION')"
  >
    <ReportTable
      :columns="[
        t('CRM_REPORTS.SALES.CONVERSION.STAGE'),
        t('CRM_REPORTS.SALES.CONVERSION.REACHED'),
        t('CRM_REPORTS.SALES.CONVERSION.MOVED_ON'),
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
            <span
              v-if="row.id === biggestDropId"
              class="text-label-small text-n-ruby-11"
            >
              {{ t('CRM_REPORTS.SALES.CONVERSION.BIGGEST_DROP') }}
            </span>
          </span>
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">
          {{ row.reached }}
        </td>
        <td
          class="px-2.5 py-2.5 text-end"
          :class="
            row.moved_on != null && row.reached
              ? 'text-n-slate-12'
              : 'text-n-slate-11'
          "
        >
          {{ movedOnText(row) }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
