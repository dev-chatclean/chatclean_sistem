<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';
import CrmReportsAPI from 'dashboard/api/crm/reports';
import ReportHeader from 'dashboard/routes/dashboard/settings/reports/components/ReportHeader.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import FilterMenu from '../components/board/FilterMenu.vue';
import FilterChips from '../components/board/FilterChips.vue';
import PipelineCard from '../components/reports/PipelineCard.vue';
import OverviewKpis from '../components/reports/overview/OverviewKpis.vue';
import VolumeChart from '../components/reports/overview/VolumeChart.vue';
import ChannelDonut from '../components/reports/overview/ChannelDonut.vue';
import AgentPerformance from '../components/reports/overview/AgentPerformance.vue';
import { buildOverviewReportCsv } from '../overviewReportCsv';
import {
  OVERVIEW_REPORT_DEFAULT_PERIOD,
  OVERVIEW_REPORT_FILTER_FIELDS,
  SALES_REPORT_PERIODS,
} from '../constants';

const { t } = useI18n();
const store = useStore();
const { run, isPending } = useAbortableRequest();

const TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;
const SHORT_PERIOD = 7;

const dateParams =
  prefix =>
  ({ from, to }) => ({
    [`${prefix}_from`]: from || undefined,
    [`${prefix}_to`]: to || undefined,
  });

// Each "Filtrar" option as the query params of the report API.
const FILTER_PARAMS = {
  team: value => ({ team_id: value }),
  channel: value => ({ inbox_id: value }),
  assignee: value => ({ assignee_id: value }),
  conversation_status: value => ({ status: value }),
  contact_label: value => ({ contact_label: value }),
  contact_type: value => ({ contact_type: value }),
  unread: () => ({ unread: 'true' }),
  created_at: dateParams('created'),
  last_activity_at: dateParams('last_activity'),
};

const period = ref(OVERVIEW_REPORT_DEFAULT_PERIOD);
const compare = ref(false);
const filters = ref([]);
const report = ref(null);
const loadFailed = ref(false);

const params = computed(() =>
  Object.assign(
    { period: period.value, time_zone: TIME_ZONE },
    ...filters.value.map(({ field, value }) => FILTER_PARAMS[field](value))
  )
);

const fetchReport = async () => {
  try {
    const response = await run(signal =>
      CrmReportsAPI.overview(params.value, { signal })
    );
    if (!response) return;
    report.value = response.data;
    loadFailed.value = false;
  } catch (error) {
    loadFailed.value = !report.value;
    useAlert(t('CRM_REPORTS.OVERVIEW.ERROR'));
  }
};

const addFilter = filter => {
  filters.value = [
    ...filters.value.filter(item => item.field !== filter.field),
    filter,
  ];
};

const removeFilter = filter => {
  filters.value = filters.value.filter(item => item !== filter);
};

const downloadCsv = () =>
  downloadCsvFile(
    t('CRM_REPORTS.OVERVIEW.CSV.FILE', { days: period.value }),
    buildOverviewReportCsv(report.value, t)
  );

watch(params, fetchReport);

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  fetchReport();
});
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <ReportHeader
      :header-title="t('CRM_REPORTS.OVERVIEW.TITLE')"
      :header-description="t('CRM_REPORTS.OVERVIEW.DESCRIPTION')"
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
      <FilterMenu :fields="OVERVIEW_REPORT_FILTER_FIELDS" @add="addFilter" />
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
      {{ t('CRM_REPORTS.OVERVIEW.ERROR') }}
    </p>
    <div v-else-if="!report" class="flex justify-center py-16">
      <Spinner />
    </div>
    <template v-else>
      <OverviewKpis
        :kpis="report.kpis"
        :previous="report.previous_kpis"
        :timeline="report.volume_timeline"
        :channels="report.by_channel"
        :compare="compare"
      />
      <div class="grid gap-4 lg:grid-cols-3">
        <VolumeChart
          class="lg:col-span-2"
          :timeline="report.volume_timeline"
          :previous="report.previous_volume_timeline"
          :compare="compare"
          :short-period="period === SHORT_PERIOD"
        />
        <ChannelDonut :channels="report.by_channel" />
      </div>
      <div class="grid gap-4 lg:grid-cols-2">
        <PipelineCard
          :title="t('CRM_REPORTS.OVERVIEW.PIPELINE.TITLE')"
          :stages="report.pipeline?.stages || []"
          :pipeline-name="report.pipeline?.name"
        />
        <AgentPerformance :agents="report.agents" />
      </div>
    </template>
  </div>
</template>
