<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import BarChart from 'shared/components/charts/BarChart.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ReportCard from './ReportCard.vue';
import { formatCurrency } from '../../dealHelpers';

const props = defineProps({
  timeline: { type: Array, required: true },
  previous: { type: Array, required: true },
  compare: { type: Boolean, default: false },
  weekly: { type: Boolean, default: false },
});

const { t, locale } = useI18n();
const asTable = ref(false);

const CURRENT_COLOR = 'rgb(var(--teal-9))';
const PREVIOUS_COLOR = 'rgb(var(--slate-8))';

const formatDay = date =>
  new Intl.DateTimeFormat(locale.value.replace('_', '-'), {
    day: '2-digit',
    month: '2-digit',
    timeZone: 'UTC',
  }).format(new Date(`${date}T00:00:00Z`));

const label = point =>
  props.weekly
    ? t('CRM_REPORTS.SALES.WINS.WEEK_OF', { date: formatDay(point.date) })
    : formatDay(point.date);

const total = computed(() =>
  props.timeline.reduce((sum, point) => sum + point.value, 0)
);

// The axis has no room for "Semana de …": it shows the first day of each week, the table the full label.
const chartData = computed(() => ({
  categories: props.timeline.map(point => formatDay(point.date)),
  series: [
    {
      id: 'current',
      label: t('CRM_REPORTS.SALES.WINS.CURRENT'),
      color: CURRENT_COLOR,
      data: props.timeline.map(point => point.value),
    },
    ...(props.compare
      ? [
          {
            id: 'previous',
            label: t('CRM_REPORTS.SALES.WINS.PREVIOUS'),
            color: PREVIOUS_COLOR,
            data: props.previous.map(point => point.value),
          },
        ]
      : []),
  ],
}));
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.SALES.WINS.TITLE')"
    :description="t('CRM_REPORTS.SALES.WINS.DESCRIPTION')"
  >
    <template #actions>
      <div class="flex items-start gap-2 shrink-0">
        <div class="flex flex-col items-end">
          <span class="text-xl font-semibold text-n-slate-12">
            {{ total ? formatCurrency(total) : t('CRM_REPORTS.SALES.NO_DATA') }}
          </span>
          <span class="text-label-small text-n-slate-11">
            {{ t('CRM_REPORTS.SALES.WINS.TOTAL') }}
          </span>
        </div>
        <Button
          v-tooltip.top="
            asTable
              ? t('CRM_REPORTS.SALES.WINS.SHOW_CHART')
              : t('CRM_REPORTS.SALES.WINS.SHOW_TABLE')
          "
          :icon="asTable ? 'i-lucide-chart-column' : 'i-lucide-table'"
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
              {{ t('CRM_REPORTS.SALES.WINS.DATE') }}
            </th>
            <th class="py-1.5 font-normal text-end">
              {{ t('CRM_REPORTS.SALES.WINS.VALUE') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="point in timeline.filter(item => item.value)"
            :key="point.date"
            class="border-t border-n-weak"
          >
            <td class="py-1.5 text-n-slate-12">{{ label(point) }}</td>
            <td class="py-1.5 text-end text-n-slate-12">
              {{ formatCurrency(point.value) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <BarChart
      v-else
      :data="chartData"
      :aria-label="t('CRM_REPORTS.SALES.WINS.TITLE')"
      :format-value="formatCurrency"
      :height="240"
      timeseries
    />
  </ReportCard>
</template>
