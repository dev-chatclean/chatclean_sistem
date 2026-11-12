<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { DonutChart } from '@chatwoot/viz';
import ReportCard from '../ReportCard.vue';
import {
  CHANNEL_COLORS,
  OTHER_CHANNEL_COLOR,
  channelKindLabel,
} from '../../../overviewReportLabels';

// Por canal: the conversations of the period per kind of channel, as a donut and a list.
const props = defineProps({
  channels: { type: Array, required: true },
});

const { t } = useI18n();

const PERCENT = 100;

const total = computed(() =>
  props.channels.reduce((sum, row) => sum + row.count, 0)
);

const rows = computed(() =>
  props.channels.map(row => ({
    ...row,
    label: channelKindLabel(row.key, t),
    color: CHANNEL_COLORS[row.key] || OTHER_CHANNEL_COLOR,
    share: total.value ? Math.round((row.count / total.value) * PERCENT) : 0,
  }))
);

const chartData = computed(() => ({
  segments: rows.value
    .filter(row => row.count)
    .map(row => ({
      id: row.key,
      label: row.label,
      value: row.count,
      color: row.color,
    })),
}));
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.OVERVIEW.BY_CHANNEL.TITLE')"
    :description="t('CRM_REPORTS.OVERVIEW.BY_CHANNEL.DESCRIPTION')"
  >
    <p v-if="!total" class="py-10 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <div v-else class="flex flex-col items-center gap-4">
      <DonutChart
        :data="chartData"
        :diameter="150"
        :thickness="18"
        :show-legend="false"
        :aria-label="t('CRM_REPORTS.OVERVIEW.BY_CHANNEL.TITLE')"
        class="[--cw-viz-donut-tooltip-background:rgb(var(--solid-2))] [--cw-viz-donut-tooltip-color:rgb(var(--slate-12))] [--cw-viz-donut-tooltip-border-color:rgb(var(--border-strong))]"
      />
      <ul class="flex flex-col w-full gap-2 text-sm">
        <li
          v-for="row in rows"
          :key="row.key"
          class="flex items-center justify-between gap-3"
        >
          <span class="flex items-center gap-2 min-w-0 text-n-slate-12">
            <span
              class="rounded-full size-2.5 shrink-0"
              :style="{ backgroundColor: row.color }"
            />
            <span class="truncate">{{ row.label }}</span>
          </span>
          <span class="shrink-0 text-n-slate-11">
            {{ `${row.count} · ${row.share}%` }}
          </span>
        </li>
      </ul>
    </div>
  </ReportCard>
</template>
