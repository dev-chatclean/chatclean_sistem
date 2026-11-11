<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import FilterMenu from './FilterMenu.vue';
import ToolbarSelect from './ToolbarSelect.vue';
import { BOARD_SORTS, CLOSED_PERIODS, OPEN_PERIODS } from '../../constants';

defineProps({
  stages: { type: Array, default: () => [] },
  summary: { type: String, default: '' },
});

const state = defineModel({ type: Object, required: true });

const { t } = useI18n();

const viewSections = computed(() => [
  {
    key: 'view',
    items: ['open', 'all'].map(value => ({
      value,
      label: t(`CRM_DEALS.TOOLBAR.VIEW.${value.toUpperCase()}`),
      selected: state.value.view === value,
    })),
  },
]);

const sortSections = computed(() => [
  {
    key: 'sort',
    items: BOARD_SORTS.map(value => ({
      value,
      label: t(`CRM_DEALS.TOOLBAR.SORT.${value.toUpperCase()}`),
      selected: state.value.sort === value,
    })),
  },
]);

const periodLabel = value =>
  value === 'any'
    ? t('CRM_DEALS.TOOLBAR.PERIOD.ANY')
    : t('CRM_DEALS.TOOLBAR.PERIOD.DAYS', { n: value });

const periodSections = computed(() => [
  {
    key: 'open',
    title: t('CRM_DEALS.TOOLBAR.PERIOD.OPEN_TITLE'),
    items: [
      ...OPEN_PERIODS.map(value => ({
        value,
        label: periodLabel(value),
        selected: state.value.openPeriod === value,
      })),
      {
        value: 'custom',
        label: t('CRM_DEALS.TOOLBAR.PERIOD.CUSTOM'),
        selected: state.value.openPeriod === 'custom',
        keepOpen: true,
      },
    ],
  },
  {
    key: 'closed',
    title: t('CRM_DEALS.TOOLBAR.PERIOD.CLOSED_TITLE'),
    items: CLOSED_PERIODS.map(value => ({
      value,
      label: periodLabel(value),
      selected: state.value.closedPeriod === value,
    })),
  },
]);

const onSelect = ({ section, value }) => {
  if (section === 'view') state.value.view = value;
  if (section === 'sort') state.value.sort = value;
  if (section === 'open') state.value.openPeriod = value;
  if (section === 'closed') state.value.closedPeriod = value;
};

const addFilter = filter => {
  state.value.filters = [
    ...state.value.filters.filter(item => item.field !== filter.field),
    filter,
  ];
};

const removeFilter = filter => {
  state.value.filters = state.value.filters.filter(item => item !== filter);
};

const filterChipText = filter => {
  const { value } = filter;
  if (filter.valueLabel) return filter.valueLabel;
  if (typeof value === 'string') return value;
  if (value === true) return t('CRM_DEALS.FILTERS.YES');
  if ('min' in value) {
    return [value.min, value.max].filter(item => item !== '').join(' – ');
  }
  return [value.from, value.to].filter(Boolean).join(' – ');
};
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <div class="relative w-72 max-w-full">
      <span
        class="absolute i-lucide-search size-3.5 top-3 start-3 text-n-slate-10"
      />
      <input
        v-model="state.search"
        type="search"
        :placeholder="t('CRM_DEALS.TOOLBAR.SEARCH')"
        class="reset-base w-full h-9 ps-9 pe-3 text-sm rounded-xl border border-n-slate-6 bg-n-solid-2 text-n-slate-12 focus:outline-none focus:border-n-brand"
      />
    </div>
    <FilterMenu :stages="stages" @add="addFilter" />
    <span
      v-for="filter in state.filters"
      :key="filter.field"
      class="flex items-center gap-1.5 h-9 ps-3 pe-1.5 text-sm rounded-xl bg-n-brand/10 text-n-slate-12"
    >
      <span class="text-n-slate-11">{{ filter.label }}:</span>
      {{ filterChipText(filter) }}
      <button
        type="button"
        class="flex items-center justify-center rounded-md size-6 hover:bg-n-alpha-2"
        :aria-label="t('CRM_DEALS.FILTERS.REMOVE')"
        @click="removeFilter(filter)"
      >
        <span class="i-lucide-x size-3.5" />
      </button>
    </span>
    <ToolbarSelect
      :label="t('CRM_DEALS.TOOLBAR.VIEW.LABEL')"
      :selected-text="t(`CRM_DEALS.TOOLBAR.VIEW.${state.view.toUpperCase()}`)"
      :sections="viewSections"
      @select="onSelect"
    />
    <ToolbarSelect
      :label="t('CRM_DEALS.TOOLBAR.SORT.LABEL')"
      :selected-text="t(`CRM_DEALS.TOOLBAR.SORT.${state.sort.toUpperCase()}`)"
      :sections="sortSections"
      @select="onSelect"
    />
    <ToolbarSelect
      icon="i-lucide-calendar"
      :selected-text="t('CRM_DEALS.TOOLBAR.PERIOD.LABEL')"
      :sections="periodSections"
      @select="onSelect"
    >
      <template #section-open>
        <div
          v-if="state.openPeriod === 'custom'"
          class="grid grid-cols-2 gap-2 px-2.5 pb-1.5"
        >
          <input
            v-model="state.customRange.from"
            type="date"
            :aria-label="t('CRM_DEALS.FILTERS.FROM')"
            class="reset-base h-8 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          />
          <input
            v-model="state.customRange.to"
            type="date"
            :aria-label="t('CRM_DEALS.FILTERS.TO')"
            class="reset-base h-8 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          />
        </div>
      </template>
    </ToolbarSelect>
    <span class="text-sm text-n-slate-11">{{ summary }}</span>
  </div>
</template>
