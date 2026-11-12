<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import CrmReportsAPI from 'dashboard/api/crm/reports';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import ReportHeader from 'dashboard/routes/dashboard/settings/reports/components/ReportHeader.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import FilterMenu from '../components/board/FilterMenu.vue';
import FilterChips from '../components/board/FilterChips.vue';
import ReportCard from '../components/reports/ReportCard.vue';
import SalesKpis from '../components/reports/SalesKpis.vue';
import PipelineStageBars from '../components/reports/PipelineStageBars.vue';
import WinsTimeline from '../components/reports/WinsTimeline.vue';
import StageConversion from '../components/reports/StageConversion.vue';
import AssigneeRanking from '../components/reports/AssigneeRanking.vue';
import StagnationTable from '../components/reports/StagnationTable.vue';
import CollaboratorsTable from '../components/reports/CollaboratorsTable.vue';
import {
  SALES_REPORT_DEFAULT_PERIOD,
  SALES_REPORT_FILTER_FIELDS,
  SALES_REPORT_PERIODS,
  SALES_REPORT_WEEKLY_PERIOD,
} from '../constants';

const { t } = useI18n();
const store = useStore();
const { run, isPending } = useAbortableRequest();

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
      <FilterMenu
        :fields="SALES_REPORT_FILTER_FIELDS"
        :stages="stageOptions"
        :pipelines="pipelines"
        @add="addFilter"
      />
      <FilterChips :filters="filters" @remove="removeFilter" />
      <Spinner v-if="isPending && report" :size="16" />
    </div>

    <p v-if="loadFailed" class="py-16 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.SALES.ERROR') }}
    </p>
    <div v-else-if="!report" class="flex justify-center py-16">
      <Spinner />
    </div>
    <template v-else>
      <SalesKpis
        :kpis="report.kpis"
        :previous="report.previous_kpis"
        :compare="compare"
      />
      <div class="grid gap-4 lg:grid-cols-2">
        <ReportCard
          :title="t('CRM_REPORTS.SALES.PIPELINE.TITLE')"
          :description="t('CRM_REPORTS.SALES.PIPELINE.DESCRIPTION')"
        >
          <template v-if="report.pipeline" #actions>
            <span class="text-label-small text-n-slate-11 shrink-0">
              {{ report.pipeline.name }}
            </span>
          </template>
          <PipelineStageBars v-if="hasStages" :stages="report.stages" />
          <p v-else class="py-6 text-sm text-center text-n-slate-11">
            {{ t('CRM_REPORTS.SALES.PIPELINE.NO_PIPELINE') }}
          </p>
        </ReportCard>
        <WinsTimeline
          :timeline="report.wins_timeline"
          :previous="report.previous_wins_timeline"
          :compare="compare"
          :weekly="period === SALES_REPORT_WEEKLY_PERIOD"
        />
        <StageConversion
          v-if="hasStages"
          class="lg:col-span-2"
          :stages="report.stages"
        />
        <AssigneeRanking :assignees="report.assignees" />
        <StagnationTable
          v-if="hasStages"
          class="lg:col-span-2"
          :stages="report.stages"
        />
        <CollaboratorsTable
          class="lg:col-span-2"
          :assignees="report.assignees"
        />
      </div>
    </template>
  </div>
</template>
