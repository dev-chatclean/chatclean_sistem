<script setup>
import { computed, onMounted, ref } from 'vue';
import parseISO from 'date-fns/parseISO';
import BarChart from 'shared/components/charts/BarChart.vue';

const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

// ChatClean (CCV2-22): verde de ação da marca.
const CHART_COLOR = '#007A2A';
const CHART_HEIGHT = 300;
const BAR_MAX_WIDTH = 28;
const BAR_RADIUS = 6;
const Y_TICK_COUNT = 4;
const AXIS_DATE_FORMAT = { day: 'numeric', month: 'short' };

const labels = computed(() => props.componentData.labels);
// Só dia e mês, sem os conectivos do idioma: "Oct 20" em inglês, "20 out." em português.
const formatDay = day =>
  new Intl.DateTimeFormat(props.componentData.locale, AXIS_DATE_FORMAT)
    .formatToParts(parseISO(day))
    .filter(({ type }) => type !== 'literal')
    .map(({ value }) => value)
    .join(' ');

const stats = ref(null);
const failed = ref(false);

const loading = computed(() => !stats.value && !failed.value);

onMounted(async () => {
  try {
    const response = await fetch(window.location.pathname, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    stats.value = await response.json();
  } catch {
    failed.value = true;
  }
});

const metrics = computed(() => [
  {
    label: labels.value.accounts,
    value: stats.value?.accountsCount,
    icon: 'i-lucide-building-2',
    tone: 'bg-n-blue-3 text-n-blue-11',
    href: props.componentData.accountsPath,
  },
  {
    label: labels.value.users,
    value: stats.value?.usersCount,
    icon: 'i-lucide-users',
    tone: 'bg-n-iris-3 text-n-iris-11',
    href: props.componentData.usersPath,
  },
  {
    label: labels.value.inboxes,
    value: stats.value?.inboxesCount,
    icon: 'i-lucide-inbox',
    tone: 'bg-n-teal-3 text-n-teal-11',
  },
  {
    label: labels.value.conversations,
    value: stats.value?.conversationsCount,
    icon: 'i-lucide-messages-square',
    tone: 'bg-n-amber-3 text-n-amber-11',
  },
]);

const chartData = computed(() => {
  const sourceData = stats.value?.chartData || [];
  return {
    categories: sourceData.map(([day]) => formatDay(day)),
    series: [
      {
        id: 'conversations',
        label: labels.value.conversations,
        color: CHART_COLOR,
        data: sourceData.map(([, value]) => value),
      },
    ],
  };
});

// Whole-number steps, so a quiet installation does not get an axis of fractions.
const yStepSize = computed(() => {
  const counts = (stats.value?.chartData || []).map(([, value]) => value);
  return Math.max(1, Math.ceil(Math.max(0, ...counts) / Y_TICK_COUNT));
});

const chartSummary = computed(() => {
  const sourceData = stats.value?.chartData || [];
  if (!sourceData.length) return [];

  const total = sourceData.reduce((sum, [, value]) => sum + value, 0);
  const [busiestDay] = sourceData.reduce((busiest, day) =>
    day[1] > busiest[1] ? day : busiest
  );

  return [
    { label: labels.value.total, value: total.toLocaleString() },
    {
      label: labels.value.daily_average,
      value: Math.round(total / sourceData.length).toLocaleString(),
    },
    {
      label: labels.value.busiest_day,
      value: formatDay(busiestDay),
    },
  ];
});
</script>

<template>
  <div class="flex flex-col gap-6 min-w-0">
    <ul
      class="grid grid-cols-2 gap-px overflow-hidden border lg:grid-cols-4 rounded-xl border-n-weak bg-n-weak"
    >
      <li v-for="item in metrics" :key="item.label" class="flex bg-n-solid-1">
        <component
          :is="item.href ? 'a' : 'div'"
          :href="item.href"
          class="flex flex-col flex-1 gap-3 p-4"
          :class="{ 'hover:bg-n-solid-3': item.href }"
        >
          <span
            class="flex items-center gap-2.5 text-body-main text-n-slate-11"
          >
            <span
              class="grid rounded-lg size-8 place-items-center shrink-0"
              :class="item.tone"
            >
              <span class="size-4" :class="item.icon" />
            </span>
            {{ item.label }}
          </span>
          <span
            class="text-3xl font-semibold tracking-tight font-interDisplay tabular-nums text-n-slate-12"
          >
            <span
              v-if="loading"
              class="inline-block w-16 rounded h-8 bg-n-slate-3 animate-pulse"
            />
            <template v-else>{{ item.value || 'N/A' }}</template>
          </span>
        </component>
      </li>
    </ul>

    <section class="p-4 border rounded-xl border-n-weak bg-n-solid-1">
      <div class="flex flex-wrap items-start justify-between gap-x-8 gap-y-3">
        <div>
          <h2 class="text-heading-3 text-n-slate-12">
            {{ labels.conversations }}
          </h2>
          <p class="text-label-small text-n-slate-11">
            {{ labels.chart_caption }}
          </p>
        </div>
        <dl class="flex flex-wrap gap-x-8 gap-y-2">
          <div v-for="item in chartSummary" :key="item.label">
            <dt
              class="text-xs font-medium uppercase tracking-wider text-n-slate-10"
            >
              {{ item.label }}
            </dt>
            <dd
              class="text-base font-semibold font-interDisplay tabular-nums text-n-slate-12"
            >
              {{ item.value }}
            </dd>
          </div>
        </dl>
      </div>
      <div
        v-if="loading"
        class="mt-4 rounded-lg h-[18.75rem] bg-n-slate-3 animate-pulse"
      />
      <p
        v-else-if="failed"
        class="py-16 text-center text-body-main text-n-slate-11"
      >
        {{ labels.load_error }}
      </p>
      <div v-else class="w-full min-w-0 mt-4">
        <BarChart
          class="![--cw-viz-bar-axis-font-size:0.6875rem] ![--cw-viz-bar-label-color:rgb(var(--slate-10))]"
          :data="chartData"
          :height="CHART_HEIGHT"
          :max-bar-width="BAR_MAX_WIDTH"
          :bar-radius="BAR_RADIUS"
          :y-step-size="yStepSize"
          timeseries
          :aria-label="labels.chart_aria_label"
        />
      </div>
    </section>
  </div>
</template>
