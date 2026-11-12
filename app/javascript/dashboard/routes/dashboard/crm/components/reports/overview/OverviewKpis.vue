<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatCurrency } from '../../../dealHelpers';
import { TREND_CLASSES, reportTrend } from '../../../reportTrend';
import {
  busiestDay,
  channelKindLabel,
  dayWithWeekday,
  leadingChannel,
} from '../../../overviewReportLabels';

// The 4 indicators and the 2 highlights at the top of the Visão geral report.
const props = defineProps({
  kpis: { type: Object, required: true },
  previous: { type: Object, required: true },
  timeline: { type: Array, required: true },
  channels: { type: Array, required: true },
  compare: { type: Boolean, default: false },
});

const { t, locale } = useI18n();

const PERCENT = 100;
const percent = value => `${Math.round(value * PERCENT)}%`;
const noData = t('CRM_REPORTS.SALES.NO_DATA');

const trend = (current, previous, key) => {
  const change = reportTrend(current, previous);
  return change && { ...change, text: t(key, { value: change.value }) };
};
const vsPrevious = (current, previous) =>
  trend(current, previous, 'CRM_REPORTS.SALES.VS_PREVIOUS');

const cards = computed(() => {
  const { kpis, previous } = props;
  return [
    {
      key: 'conversations',
      label: t('CRM_REPORTS.OVERVIEW.KPIS.CONVERSATIONS.LABEL'),
      value: kpis.conversations,
      trend: trend(
        kpis.conversations,
        previous.conversations,
        'CRM_REPORTS.OVERVIEW.KPIS.CONVERSATIONS.TREND'
      ),
      alwaysTrend: true,
    },
    {
      key: 'open',
      label: t('CRM_REPORTS.OVERVIEW.KPIS.OPEN.LABEL'),
      value: kpis.open_count,
      hint: t('CRM_REPORTS.OVERVIEW.KPIS.OPEN.HINT', {
        count: kpis.waiting_count,
      }),
    },
    {
      key: 'won',
      label: t('CRM_REPORTS.OVERVIEW.KPIS.WON.LABEL'),
      value: kpis.won_count ? formatCurrency(kpis.won_value) : noData,
      hint: t(
        'CRM_REPORTS.OVERVIEW.KPIS.WON.HINT',
        { count: kpis.won_count },
        kpis.won_count
      ),
      trend: vsPrevious(kpis.won_value, previous.won_value),
    },
    {
      key: 'conversion',
      label: t('CRM_REPORTS.OVERVIEW.KPIS.CONVERSION.LABEL'),
      value: kpis.conversion == null ? noData : percent(kpis.conversion),
      hint:
        kpis.conversion == null
          ? t('CRM_REPORTS.OVERVIEW.KPIS.CONVERSION.EMPTY')
          : t('CRM_REPORTS.OVERVIEW.KPIS.CONVERSION.HINT'),
      trend:
        kpis.conversion == null
          ? null
          : vsPrevious(kpis.conversion, previous.conversion),
    },
  ];
});

const highlights = computed(() => {
  const channel = leadingChannel(props.channels);
  const day = busiestDay(props.timeline);
  const empty = t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.EMPTY');
  return [
    {
      key: 'channel',
      icon: 'i-lucide-trophy',
      label: t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.TOP_CHANNEL.LABEL'),
      value: channel ? channelKindLabel(channel.key, t) : noData,
      hint: channel
        ? t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.TOP_CHANNEL.HINT', {
            value: percent(channel.share),
          })
        : empty,
    },
    {
      key: 'day',
      icon: 'i-lucide-trending-up',
      label: t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.BEST_DAY.LABEL'),
      value: day ? dayWithWeekday(day.date, locale.value) : noData,
      hint: day
        ? t(
            'CRM_REPORTS.OVERVIEW.HIGHLIGHTS.BEST_DAY.HINT',
            { count: day.count },
            day.count
          )
        : empty,
    },
  ];
});

const showTrend = card => card.trend && (card.alwaysTrend || props.compare);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <div
        v-for="card in cards"
        :key="card.key"
        class="flex flex-col gap-1 px-4 py-3 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
      >
        <span class="text-sm text-n-slate-11">{{ card.label }}</span>
        <span class="text-lg font-semibold text-n-slate-12">
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
    <div class="grid gap-3 sm:grid-cols-2">
      <div
        v-for="item in highlights"
        :key="item.key"
        class="flex items-center gap-3 px-4 py-3 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
      >
        <span
          class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-11"
        >
          <span class="size-4" :class="item.icon" />
        </span>
        <div class="flex flex-col min-w-0">
          <span class="text-label-small text-n-slate-11">{{ item.label }}</span>
          <span class="font-semibold truncate text-n-slate-12">
            {{ item.value }}
          </span>
          <span class="text-label-small text-n-slate-11">{{ item.hint }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
