<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';
import CrmReportsAPI from 'dashboard/api/crm/reports';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import ReportHeader from 'dashboard/routes/dashboard/settings/reports/components/ReportHeader.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import FilterMenu from '../components/board/FilterMenu.vue';
import FilterChips from '../components/board/FilterChips.vue';
import BlocksMenu from '../components/reports/BlocksMenu.vue';
import SalesKpis from '../components/reports/SalesKpis.vue';
import PipelineCard from '../components/reports/PipelineCard.vue';
import WinsTimeline from '../components/reports/WinsTimeline.vue';
import StageConversion from '../components/reports/StageConversion.vue';
import AssigneeRanking from '../components/reports/AssigneeRanking.vue';
import SourceTable from '../components/reports/SourceTable.vue';
import ProductsTable from '../components/reports/ProductsTable.vue';
import ShareBars from '../components/reports/ShareBars.vue';
import CompaniesTable from '../components/reports/CompaniesTable.vue';
import ReasonsTable from '../components/reports/ReasonsTable.vue';
import DealsTable from '../components/reports/DealsTable.vue';
import LossesByAssignee from '../components/reports/LossesByAssignee.vue';
import WhereLostTable from '../components/reports/WhereLostTable.vue';
import StagnationTable from '../components/reports/StagnationTable.vue';
import CollaboratorsTable from '../components/reports/CollaboratorsTable.vue';
import { buildSalesReportCsv } from '../salesReportCsv';
import { channelLabel, originLabel } from '../salesReportLabels';
import {
  SALES_REPORT_BLOCKS,
  SALES_REPORT_DEALS_LIMIT,
  SALES_REPORT_DEFAULT_PERIOD,
  SALES_REPORT_FILTER_FIELDS,
  SALES_REPORT_PERIODS,
  SALES_REPORT_UI_KEY,
  SALES_REPORT_WEEKLY_PERIOD,
} from '../constants';

const { t } = useI18n();
const store = useStore();
const { run, isPending } = useAbortableRequest();
const { uiSettings, updateUISettings } = useUISettings();

const TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;

const dateParams =
  prefix =>
  ({ from, to }) => ({
    [`${prefix}_from`]: from || undefined,
    [`${prefix}_to`]: to || undefined,
  });

// Each "Filtrar" option as the query params of the report API.
const FILTER_PARAMS = {
  pipeline: value => ({ pipeline_id: value }),
  stage: value => ({ stage_id: value }),
  assignee: value => ({ assignee_id: value }),
  channel: value => ({ inbox_id: value }),
  contact: value => ({ contact: value }),
  company: value => ({ company: value }),
  title: value => ({ title: value }),
  value: ({ min, max }) => ({
    value_min: min || undefined,
    value_max: max || undefined,
  }),
  closed_at: dateParams('closed'),
  created_at: dateParams('created'),
  stage_entered_at: dateParams('stage_entered'),
};

const BLOCK_COMPONENTS = {
  indicators: SalesKpis,
  pipeline: PipelineCard,
  wins: WinsTimeline,
  conversion: StageConversion,
  by_assignee: AssigneeRanking,
  by_origin: SourceTable,
  by_channel: SourceTable,
  by_product: ProductsTable,
  origin_wins: ShareBars,
  by_company: CompaniesTable,
  won_reasons: ReasonsTable,
  won_deals: DealsTable,
  lost_reasons: ReasonsTable,
  lost_by_assignee: LossesByAssignee,
  where_lost: WhereLostTable,
  lost_deals: DealsTable,
  stagnation: StagnationTable,
  collaborators: CollaboratorsTable,
};

const period = ref(SALES_REPORT_DEFAULT_PERIOD);
const compare = ref(false);
const filters = ref([]);
const pipelines = ref([]);
const report = ref(null);
const loadFailed = ref(false);

const params = computed(() =>
  Object.assign(
    { period: period.value, time_zone: TIME_ZONE },
    ...filters.value.map(({ field, value }) => FILTER_PARAMS[field](value))
  )
);

const stageOptions = computed(() => report.value?.pipeline?.stages || []);
const hasStages = computed(() => Boolean(report.value?.stages.length));

// Order and hidden blocks are the user's own preference, kept in their UI settings.
const blockSettings = computed(
  () => uiSettings.value[SALES_REPORT_UI_KEY] || {}
);

const blocks = computed(() => {
  const { order = [], hidden = [] } = blockSettings.value;
  const rank = block => {
    const index = order.indexOf(block.key);
    return index === -1 ? order.length : index;
  };
  return [...SALES_REPORT_BLOCKS]
    .sort((a, b) => rank(a) - rank(b))
    .map(block => ({
      ...block,
      label: t(`CRM_REPORTS.SALES.BLOCKS.NAMES.${block.key.toUpperCase()}`),
      visible: !hidden.includes(block.key),
    }));
});

const visibleBlocks = computed(() =>
  blocks.value.filter(
    block => block.visible && (!block.needsStages || hasStages.value)
  )
);

const saveBlocks = changes =>
  updateUISettings({
    [SALES_REPORT_UI_KEY]: { ...blockSettings.value, ...changes },
  });

const toggleBlock = key => {
  const { hidden = [] } = blockSettings.value;
  saveBlocks({
    hidden: hidden.includes(key)
      ? hidden.filter(item => item !== key)
      : [...hidden, key],
  });
};

const originRows = rows =>
  rows.map(row => ({
    ...row,
    key: row.key ?? 'none',
    label: originLabel(row.key, t),
  }));

const blockProps = computed(() => {
  const data = report.value;
  return {
    indicators: {
      kpis: data.kpis,
      previous: data.previous_kpis,
      compare: compare.value,
    },
    pipeline: { stages: data.stages, pipelineName: data.pipeline?.name },
    wins: {
      timeline: data.wins_timeline,
      previous: data.previous_wins_timeline,
      compare: compare.value,
      weekly: period.value === SALES_REPORT_WEEKLY_PERIOD,
    },
    conversion: { stages: data.stages },
    by_assignee: { assignees: data.assignees },
    by_origin: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.BY_ORIGIN'),
      description: t('CRM_REPORTS.SALES.BY_ORIGIN.DESCRIPTION'),
      firstColumn: t('CRM_REPORTS.SALES.BY_ORIGIN.ORIGIN'),
      rows: originRows(data.by_origin),
    },
    by_channel: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.BY_CHANNEL'),
      description: t('CRM_REPORTS.SALES.BY_CHANNEL.DESCRIPTION'),
      firstColumn: t('CRM_REPORTS.SALES.BY_CHANNEL.CHANNEL'),
      rows: data.by_channel.map(row => ({
        ...row,
        key: row.key ?? 'none',
        label: channelLabel(row, t),
      })),
    },
    by_product: { products: data.by_product },
    origin_wins: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.ORIGIN_WINS'),
      description: t('CRM_REPORTS.SALES.ORIGIN_WINS.DESCRIPTION'),
      rows: originRows(data.origin_wins),
    },
    by_company: { companies: data.by_company },
    won_reasons: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.WON_REASONS'),
      description: t('CRM_REPORTS.SALES.WON_REASONS.DESCRIPTION'),
      empty: t('CRM_REPORTS.SALES.WON_REASONS.EMPTY'),
      reasons: data.won_reasons,
    },
    won_deals: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.WON_DEALS'),
      description: t('CRM_REPORTS.SALES.WON_DEALS.DESCRIPTION'),
      empty: t('CRM_REPORTS.SALES.WON_DEALS.EMPTY'),
      deals: data.won_deals,
      limit: SALES_REPORT_DEALS_LIMIT,
    },
    lost_reasons: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.LOST_REASONS'),
      description: t('CRM_REPORTS.SALES.LOST_REASONS.DESCRIPTION'),
      empty: t('CRM_REPORTS.SALES.LOST_REASONS.EMPTY'),
      reasons: data.lost_reasons,
      barClass: 'bg-n-ruby-9',
    },
    lost_by_assignee: { assignees: data.assignees },
    where_lost: { stages: data.where_lost },
    lost_deals: {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.LOST_DEALS'),
      description: t('CRM_REPORTS.SALES.LOST_DEALS.DESCRIPTION'),
      empty: t('CRM_REPORTS.SALES.LOST_DEALS.EMPTY'),
      deals: data.lost_deals,
      limit: SALES_REPORT_DEALS_LIMIT,
      lost: true,
    },
    stagnation: { stages: data.stages },
    collaborators: { assignees: data.assignees },
  };
});

const downloadCsv = () =>
  downloadCsvFile(
    t('CRM_REPORTS.SALES.CSV.FILE', { days: period.value }),
    buildSalesReportCsv(
      report.value,
      visibleBlocks.value.map(block => block.key),
      t
    )
  );

const fetchReport = async () => {
  try {
    const response = await run(signal =>
      CrmReportsAPI.sales(params.value, { signal })
    );
    if (!response) return;
    report.value = response.data;
    loadFailed.value = false;
  } catch (error) {
    loadFailed.value = !report.value;
    useAlert(t('CRM_REPORTS.SALES.ERROR'));
  }
};

// A new pipeline filter drops the stage filter, whose stages belong to the previous pipeline.
const addFilter = filter => {
  filters.value = [
    ...filters.value.filter(
      item =>
        item.field !== filter.field &&
        !(filter.field === 'pipeline' && item.field === 'stage')
    ),
    filter,
  ];
};

const removeFilter = filter => {
  filters.value = filters.value.filter(item => item !== filter);
};

watch(params, fetchReport);

onMounted(async () => {
  store.dispatch('agents/get');
  fetchReport();
  const { data } = await CrmPipelinesAPI.get();
  pipelines.value = data.payload;
});
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <ReportHeader
      :header-title="t('CRM_REPORTS.SALES.TITLE')"
      :header-description="t('CRM_REPORTS.SALES.DESCRIPTION')"
    />
    <div class="flex flex-wrap items-center gap-2">
      <div class="flex p-0.5 rounded-xl bg-n-alpha-2">
        <button
          v-for="value in SALES_REPORT_PERIODS"
          :key="value"
          type="button"
          class="h-8 px-3 text-sm rounded-lg"
          :class="
            period === value
              ? 'bg-n-solid-1 text-n-slate-12 shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="period = value"
        >
          {{ t('CRM_REPORTS.SALES.PERIOD_DAYS', { count: value }) }}
        </button>
      </div>
      <button
        type="button"
        class="h-9 px-3 text-sm border rounded-xl"
        :class="
          compare
            ? 'border-n-brand bg-n-brand/10 text-n-slate-12'
            : 'border-n-slate-6 bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12'
        "
        :aria-pressed="compare"
        @click="compare = !compare"
      >
        {{ t('CRM_REPORTS.SALES.PREVIOUS') }}
      </button>
      <BlocksMenu
        :blocks="blocks"
        @reorder="order => saveBlocks({ order })"
        @toggle="toggleBlock"
        @show-all="saveBlocks({ hidden: [] })"
      />
      <FilterMenu
        :fields="SALES_REPORT_FILTER_FIELDS"
        :stages="stageOptions"
        :pipelines="pipelines"
        @add="addFilter"
      />
      <FilterChips :filters="filters" @remove="removeFilter" />
      <Spinner v-if="isPending && report" :size="16" />
      <button
        type="button"
        class="flex items-center gap-1.5 h-9 px-3 text-sm border rounded-xl ms-auto border-n-slate-6 bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12 disabled:opacity-50"
        :disabled="!report"
        @click="downloadCsv"
      >
        <span class="i-lucide-download size-3.5" />
        {{ t('CRM_REPORTS.SALES.DOWNLOAD_CSV') }}
      </button>
    </div>

    <p v-if="loadFailed" class="py-16 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.ERROR') }}
    </p>
    <div v-else-if="!report" class="flex justify-center py-16">
      <Spinner />
    </div>
    <div v-else class="grid gap-4 lg:grid-cols-2 lg:grid-flow-row-dense">
      <component
        :is="BLOCK_COMPONENTS[block.key]"
        v-for="block in visibleBlocks"
        :key="block.key"
        v-bind="blockProps[block.key]"
        :class="{ 'lg:col-span-2': block.wide }"
      />
    </div>
  </div>
</template>
