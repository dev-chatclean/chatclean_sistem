<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatCurrency } from '../../dealHelpers';
import { formatDuration } from '../deals/detail/dealTime';

const props = defineProps({
  kpis: { type: Object, required: true },
  previous: { type: Object, required: true },
  compare: { type: Boolean, default: false },
});

const { t } = useI18n();

const PERCENT = 100;
const TREND_CLASSES = {
  better: 'text-n-teal-11',
  worse: 'text-n-ruby-11',
  same: 'text-n-slate-11',
};

const percent = value => `${Math.round(value * PERCENT)}%`;

// Relative change against the previous period; null when there is nothing to compare with.
const trend = (current, previous, { lowerIsBetter = false } = {}) => {
  if (!previous) {
    if (current) return null;
    return {
      text: t('CRM_REPORTS.SALES.VS_PREVIOUS', { value: '0%' }),
      tone: 'same',
      up: true,
    };
  }
  const change = (current - previous) / previous;
  const sign = change > 0 ? '+' : '';
  let tone = 'same';
  if (change !== 0) tone = change > 0 !== lowerIsBetter ? 'better' : 'worse';
  return {
    text: t('CRM_REPORTS.SALES.VS_PREVIOUS', {
      value: `${sign}${percent(change)}`,
    }),
    tone,
    up: change >= 0,
  };
};

const noData = t('CRM_REPORTS.SALES.NO_DATA');

const cards = computed(() => {
  const { kpis, previous } = props;
  const closed = kpis.won_count + kpis.lost_count;
  return [
    {
      key: 'open',
      label: t('CRM_REPORTS.SALES.KPIS.OPEN.LABEL'),
      value: formatCurrency(kpis.open_value),
      hint: t(
        'CRM_REPORTS.SALES.KPIS.OPEN.HINT',
        { count: kpis.stale_count },
        kpis.stale_count
      ),
    },
    {
      key: 'won',
      label: t('CRM_REPORTS.SALES.KPIS.WON.LABEL'),
      value: kpis.won_count ? formatCurrency(kpis.won_value) : noData,
      trend: trend(kpis.won_value, previous.won_value),
      alwaysTrend: true,
    },
    {
      key: 'lost',
      label: t('CRM_REPORTS.SALES.KPIS.LOST.LABEL'),
      value: kpis.lost_count ? formatCurrency(kpis.lost_value) : noData,
      hint: t(
        'CRM_REPORTS.SALES.KPIS.LOST.HINT',
        { count: kpis.lost_count },
        kpis.lost_count
      ),
      trend: trend(kpis.lost_value, previous.lost_value, {
        lowerIsBetter: true,
      }),
    },
    {
      key: 'conversion',
      label: t('CRM_REPORTS.SALES.KPIS.CONVERSION.LABEL'),
      value: kpis.conversion == null ? noData : percent(kpis.conversion),
      hint:
        kpis.conversion == null
          ? t('CRM_REPORTS.SALES.KPIS.CONVERSION.EMPTY')
          : t('CRM_REPORTS.SALES.KPIS.CONVERSION.HINT', {
              won: kpis.won_count,
              closed,
            }),
      trend: trend(kpis.conversion, previous.conversion),
    },
    {
      key: 'ticket',
      label: t('CRM_REPORTS.SALES.KPIS.TICKET.LABEL'),
      value:
        kpis.average_ticket == null
          ? noData
          : formatCurrency(kpis.average_ticket),
      hint:
        kpis.average_ticket == null
          ? t('CRM_REPORTS.SALES.KPIS.TICKET.EMPTY')
          : t('CRM_REPORTS.SALES.KPIS.TICKET.HINT'),
      trend: trend(kpis.average_ticket, previous.average_ticket),
    },
    {
      key: 'close_time',
      label: t('CRM_REPORTS.SALES.KPIS.CLOSE_TIME.LABEL'),
      value:
        kpis.close_seconds == null
          ? noData
          : formatDuration(kpis.close_seconds, t),
      hint:
        kpis.close_seconds == null
          ? t('CRM_REPORTS.SALES.KPIS.CLOSE_TIME.EMPTY')
          : t('CRM_REPORTS.SALES.KPIS.CLOSE_TIME.HINT'),
      trend: trend(kpis.close_seconds, previous.close_seconds, {
        lowerIsBetter: true,
      }),
      wide: true,
    },
    {
      key: 'loss_time',
      label: t('CRM_REPORTS.SALES.KPIS.LOSS_TIME.LABEL'),
      value:
        kpis.loss_seconds == null
          ? noData
          : formatDuration(kpis.loss_seconds, t),
      hint: t('CRM_REPORTS.SALES.KPIS.LOSS_TIME.HINT'),
      wide: true,
    },
  ];
});

const showTrend = card => card.trend && (card.alwaysTrend || props.compare);
</script>

<template>
  <div class="grid grid-cols-2 gap-3 lg:grid-cols-10">
    <div
      v-for="card in cards"
      :key="card.key"
      class="flex flex-col gap-1 px-4 py-3 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
      :class="
        card.wide ? 'col-span-2 lg:col-span-5' : 'col-span-1 lg:col-span-2'
      "
    >
      <span class="text-sm text-n-slate-11">{{ card.label }}</span>
      <span
        class="font-semibold text-n-slate-12"
        :class="card.wide ? 'text-2xl' : 'text-lg'"
      >
        {{ card.value }}
      </span>
      <span v-if="card.hint" class="text-label-small text-n-slate-11">
        {{ card.hint }}
      </span>
      <span
        v-if="showTrend(card)"
        class="flex items-center gap-1 text-label-small"
        :class="TREND_CLASSES[card.trend.tone]"
      >
        <span
          class="size-3.5"
          :class="
            card.trend.up ? 'i-lucide-trending-up' : 'i-lucide-trending-down'
          "
        />
        {{ card.trend.text }}
      </span>
    </div>
  </div>
</template>
