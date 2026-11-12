<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { LineChart } from '@chatwoot/viz';
import Button from 'dashboard/components-next/button/Button.vue';
import ReportCard from '../ReportCard.vue';
import { axisDay, dayWithWeekday } from '../../../overviewReportLabels';

// Volume de conversas: conversations created per day, with the previous period as a gray line.
const props = defineProps({
  timeline: { type: Array, required: true },
  previous: { type: Array, required: true },
  compare: { type: Boolean, default: false },
  shortPeriod: { type: Boolean, default: false },
});

const { t, locale } = useI18n();
const asTable = ref(false);

const total = computed(() =>
  props.timeline.reduce((sum, point) => sum + point.count, 0)
);
const average = computed(() => {
  const value = props.timeline.length ? total.value / props.timeline.length : 0;
  return new Intl.NumberFormat(locale.value.replace('_', '-'), {
    maximumFractionDigits: value < 1 ? 2 : 1,
  }).format(value);
});

// Whole conversations on the axis: about 5 ticks, never fractions.
const TICKS = 5;
const highest = computed(() => {
  const points = [...props.timeline, ...(props.compare ? props.previous : [])];
  return Math.max(...points.map(point => point.count), 1);
});
const yStep = computed(() => Math.max(1, Math.ceil(highest.value / TICKS)));
const yDomain = computed(() => [
  0,
  Math.ceil(highest.value / yStep.value) * yStep.value,
]);

// Dense periods hide the axis labels, which this chart cannot thin out, and show the first, middle and last days.
const axisEdges = computed(() => {
  const { timeline } = props;
  if (props.shortPeriod || !timeline.length) return [];
  return [0, Math.floor((timeline.length - 1) / 2), timeline.length - 1].map(
    index => axisDay(timeline[index].date, locale.value, false)
  );
});

const chartData = computed(() => ({
  categories: props.timeline.map(point =>
    axisDay(point.date, locale.value, props.shortPeriod)
  ),
  series: [
    {
      id: 'current',
      label: t('CRM_REPORTS.OVERVIEW.VOLUME.CURRENT'),
      color: 'rgb(var(--teal-9))',
      pointBorderColor: 'rgb(var(--solid-2))',
      data: props.timeline.map(point => point.count),
    },
    ...(props.compare
      ? [
          {
            id: 'previous',
            label: t('CRM_REPORTS.OVERVIEW.VOLUME.PREVIOUS'),
            color: 'rgb(var(--slate-8))',
            pointBorderColor: 'rgb(var(--solid-2))',
            data: props.previous.map(point => point.count),
          },
        ]
      : []),
  ],
}));
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.OVERVIEW.VOLUME.TITLE')"
    :description="t('CRM_REPORTS.OVERVIEW.VOLUME.DESCRIPTION')"
  >
    <template #actions>
      <div class="flex items-start gap-2 shrink-0">
        <div class="flex flex-col items-end">
          <span class="text-xl font-semibold text-n-slate-12">{{ total }}</span>
          <span class="text-label-small text-n-slate-11">
            {{ t('CRM_REPORTS.OVERVIEW.VOLUME.TOTAL', { average }) }}
          </span>
        </div>
        <Button
          v-tooltip.top="
            asTable
              ? t('CRM_REPORTS.SALES.WINS.SHOW_CHART')
              : t('CRM_REPORTS.SALES.WINS.SHOW_TABLE')
          "
          :icon="asTable ? 'i-lucide-chart-spline' : 'i-lucide-table'"
          slate
          faded
          xs
          :aria-label="t('CRM_REPORTS.SALES.WINS.SHOW_TABLE')"
          @click="asTable = !asTable"
        />
      </div>
    </template>
    <p v-if="!total" class="py-10 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.EMPTY_PERIOD') }}
    </p>
    <div v-else-if="asTable" class="overflow-y-auto max-h-72">
      <table class="w-full text-sm">
        <thead>
          <tr class="text-label-small text-n-slate-11">
            <th class="py-1.5 font-normal text-start">
              {{ t('CRM_REPORTS.OVERVIEW.VOLUME.DATE') }}
            </th>
            <th class="py-1.5 font-normal text-end">
              {{ t('CRM_REPORTS.OVERVIEW.VOLUME.COUNT') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="point in timeline.filter(item => item.count)"
            :key="point.date"
            class="border-t border-n-weak"
          >
            <td class="py-1.5 text-n-slate-12">
              {{ dayWithWeekday(point.date, locale) }}
            </td>
            <td class="py-1.5 text-end text-n-slate-12">{{ point.count }}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div
      v-else
      class="flex flex-col gap-1 [&[data-dense='true']_.cw-viz-line\_\_axis-label--x]:!hidden"
      :data-dense="axisEdges.length > 0"
    >
      <LineChart
        :data="chartData"
        :height="240"
        :point-radius="3"
        :y-step-size="yStep"
        :y-domain="yDomain"
        :show-values="false"
        :aria-label="t('CRM_REPORTS.OVERVIEW.VOLUME.TITLE')"
        class="[--cw-viz-line-label-color:rgb(var(--slate-11))] [--cw-viz-line-axis-color:rgb(var(--slate-6))] [--cw-viz-line-axis-font-size:0.75rem] [--cw-viz-line-value-font-size:0.75rem] [--cw-viz-line-tooltip-background:rgb(var(--solid-2))] [--cw-viz-line-tooltip-color:rgb(var(--slate-12))] [--cw-viz-line-tooltip-label-color:rgb(var(--slate-11))] [--cw-viz-line-tooltip-active-color:rgb(var(--slate-12))] [--cw-viz-line-tooltip-border-color:rgb(var(--border-strong))]"
      />
      <div
        v-if="axisEdges.length"
        class="flex justify-between -mt-6 ps-10 text-label-small text-n-slate-11"
      >
        <span v-for="(day, index) in axisEdges" :key="index">{{ day }}</span>
      </div>
    </div>
  </ReportCard>
</template>
