<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  stages: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const total = computed(() =>
  props.stages.reduce((sum, stage) => sum + stage.open_count, 0)
);
const top = computed(() => props.stages[0]?.open_count || 0);
const largest = computed(() =>
  Math.max(...props.stages.map(stage => stage.open_count), 0)
);

const share = (count, base) =>
  base ? Math.round((count / base) * PERCENT) : 0;

const width = stage =>
  largest.value ? `${(stage.open_count / largest.value) * PERCENT}%` : '0%';

const tooltip = stage =>
  t('CRM_REPORTS.SALES.PIPELINE.TOOLTIP', {
    count: stage.open_count,
    value: formatCurrency(stage.open_value),
    total: share(stage.open_count, total.value),
    top: share(stage.open_count, top.value),
  });
</script>

<template>
  <div class="flex flex-col gap-3">
    <div
      v-for="stage in stages"
      :key="stage.id"
      v-tooltip.top="tooltip(stage)"
      class="grid items-center grid-cols-[9rem_minmax(0,1fr)_6rem] gap-3 text-sm"
    >
      <span class="truncate text-end text-n-slate-11">{{ stage.name }}</span>
      <div class="h-7 rounded-full bg-n-alpha-2">
        <div
          class="flex items-center justify-end h-full px-2.5 rounded-full min-w-9 text-label-small font-medium text-n-slate-12"
          :style="{ width: width(stage), backgroundColor: stage.color }"
        >
          {{ stage.open_count }}
        </div>
      </div>
      <span class="text-end text-n-slate-12">
        {{
          stage.open_count
            ? formatCurrency(stage.open_value)
            : t('CRM_REPORTS.SALES.NO_DATA')
        }}
      </span>
    </div>
  </div>
</template>
