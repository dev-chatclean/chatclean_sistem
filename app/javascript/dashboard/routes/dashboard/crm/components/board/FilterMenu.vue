<script setup>
import { computed, ref, watch } from 'vue';
import CrmProductsAPI from 'dashboard/api/crm/products';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  ACTIVITY_FILTERS,
  BOARD_FILTER_FIELDS,
  LEAD_ORIGINS,
  LOSS_REASONS,
} from '../../constants';

const props = defineProps({
  stages: { type: Array, default: () => [] },
  pipelines: { type: Array, default: () => [] },
  fields: { type: Array, default: () => BOARD_FILTER_FIELDS },
});

const emit = defineEmits(['add']);

const { t } = useI18n();
const agents = useMapGetter('agents/getAgents');
const labels = useMapGetter('labels/getLabels');
const inboxes = useMapGetter('inboxes/getInboxes');

const isOpen = ref(false);
const query = ref('');
const field = ref(null);
const draft = ref(null);
const products = ref([]);

const usesProducts = computed(() =>
  props.fields.some(item => item.type === 'product')
);

watch(isOpen, async open => {
  if (!open || products.value.length || !usesProducts.value) return;
  const { data } = await CrmProductsAPI.get();
  products.value = data.payload;
});

const fieldLabel = key => t(`CRM_DEALS.FILTERS.FIELDS.${key.toUpperCase()}`);

const visibleFields = computed(() => {
  const term = query.value.trim().toLowerCase();
  return props.fields.filter(
    item => !term || fieldLabel(item.key).toLowerCase().includes(term)
  );
});

const options = computed(() => {
  if (!field.value) return [];
  if (field.value.type === 'assignee') {
    return agents.value.map(agent => ({
      value: agent.id,
      label: agent.available_name || agent.name,
    }));
  }
  if (field.value.type === 'label') {
    return labels.value.map(label => ({
      value: label.title,
      label: label.title,
    }));
  }
  if (field.value.type === 'lead_origin') {
    return LEAD_ORIGINS.map(value => ({
      value,
      label: t(`CRM_PIPELINES.LEAD_ENTRY.OPTIONS.${value.toUpperCase()}`),
    }));
  }
  if (field.value.type === 'inbox') {
    return inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }));
  }
  if (field.value.type === 'product') {
    return products.value.map(product => ({
      value: product.id,
      label: product.name,
    }));
  }
  if (field.value.type === 'activity') {
    return ACTIVITY_FILTERS.map(value => ({
      value,
      label: t(`CRM_DEALS.FILTERS.ACTIVITIES.${value.toUpperCase()}`),
    }));
  }
  if (field.value.type === 'pipeline') {
    return props.pipelines.map(pipeline => ({
      value: pipeline.id,
      label: pipeline.name,
    }));
  }
  if (field.value.type === 'stage') {
    return props.stages.map(stage => ({ value: stage.id, label: stage.name }));
  }
  if (field.value.type === 'status') {
    return ['open', 'won', 'lost'].map(value => ({
      value,
      label: t(`CRM_DEALS.STATUS.${value.toUpperCase()}`),
    }));
  }
  if (field.value.type === 'loss_reason') {
    return LOSS_REASONS.map(value => ({
      value,
      label: t(`CRM_DEALS.REASONS.${value.toUpperCase()}`),
    }));
  }
  return [];
});

const DRAFTS = {
  range: () => ({ min: '', max: '' }),
  date: () => ({ from: '', to: '' }),
  text: () => '',
  flag: () => true,
};

const chooseField = item => {
  field.value = item;
  draft.value = (DRAFTS[item.type] || (() => null))();
};

const canApply = computed(() => {
  if (!field.value) return false;
  const value = draft.value;
  if (field.value.type === 'range') return value.min !== '' || value.max !== '';
  if (field.value.type === 'date') return Boolean(value.from || value.to);
  if (field.value.type === 'text') return Boolean(value.trim());
  if (field.value.type === 'flag') return true;
  return value !== null;
});

const reset = () => {
  field.value = null;
  draft.value = null;
  query.value = '';
};

const close = () => {
  isOpen.value = false;
  reset();
};

const apply = () => {
  if (!canApply.value) return;
  const option = options.value.find(item => item.value === draft.value);
  emit('add', {
    field: field.value.key,
    value: draft.value,
    label: fieldLabel(field.value.key),
    valueLabel: option?.label,
  });
  close();
};
</script>

<template>
  <div v-on-click-outside="close" class="relative">
    <button
      type="button"
      class="flex items-center gap-1.5 h-9 px-3 text-sm rounded-xl outline-dashed outline-1 -outline-offset-1 outline-n-slate-7 bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12"
      @click="isOpen ? close() : (isOpen = true)"
    >
      <span class="i-lucide-filter size-3.5" />
      {{ t('CRM_DEALS.FILTERS.BUTTON') }}
    </button>
    <div
      v-if="isOpen"
      class="absolute z-50 flex flex-col gap-1 p-1.5 mt-1 w-72 rounded-xl border border-n-slate-6 bg-n-solid-2 shadow-lg top-full start-0"
    >
      <template v-if="!field">
        <input
          v-model="query"
          type="search"
          :placeholder="t('CRM_DEALS.FILTERS.SEARCH')"
          class="reset-base h-8 px-2.5 mb-1 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 focus:outline-none focus:border-n-brand"
        />
        <div class="flex flex-col max-h-72 overflow-y-auto">
          <button
            v-for="item in visibleFields"
            :key="item.key"
            type="button"
            class="flex items-center gap-2 h-8 px-2.5 text-sm text-start rounded-lg text-n-slate-12 hover:bg-n-alpha-2"
            @click="chooseField(item)"
          >
            <span class="size-3.5 text-n-slate-11" :class="item.icon" />
            {{ fieldLabel(item.key) }}
          </button>
        </div>
      </template>
      <div v-else class="flex flex-col gap-3 p-1.5">
        <button
          type="button"
          class="flex items-center gap-1 text-label-small text-n-slate-11 hover:text-n-slate-12"
          @click="reset"
        >
          <span class="i-lucide-chevron-left size-3.5" />
          {{ fieldLabel(field.key) }}
        </button>
        <select
          v-if="options.length"
          v-model="draft"
          class="reset-base h-9 ps-2.5 pe-6 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
        >
          <option :value="null" disabled>
            {{ t('CRM_DEALS.FILTERS.CHOOSE') }}
          </option>
          <option
            v-for="option in options"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
        <input
          v-else-if="field.type === 'text'"
          v-model="draft"
          type="text"
          :placeholder="t('CRM_DEALS.FILTERS.CONTAINS')"
          class="reset-base h-9 px-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          @keydown.enter="apply"
        />
        <div v-else-if="field.type === 'range'" class="grid grid-cols-2 gap-2">
          <input
            v-model="draft.min"
            type="number"
            min="0"
            :placeholder="t('CRM_DEALS.FILTERS.MIN')"
            class="reset-base h-9 px-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          />
          <input
            v-model="draft.max"
            type="number"
            min="0"
            :placeholder="t('CRM_DEALS.FILTERS.MAX')"
            class="reset-base h-9 px-2.5 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          />
        </div>
        <div v-else-if="field.type === 'date'" class="grid grid-cols-2 gap-2">
          <label class="flex flex-col gap-1 text-label-small text-n-slate-11">
            {{ t('CRM_DEALS.FILTERS.FROM') }}
            <input
              v-model="draft.from"
              type="date"
              class="reset-base h-9 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
            />
          </label>
          <label class="flex flex-col gap-1 text-label-small text-n-slate-11">
            {{ t('CRM_DEALS.FILTERS.TO') }}
            <input
              v-model="draft.to"
              type="date"
              class="reset-base h-9 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
            />
          </label>
        </div>
        <span v-else-if="field.type === 'flag'" class="text-sm text-n-slate-11">
          {{ t('CRM_DEALS.FILTERS.STALE_HINT') }}
        </span>
        <span v-else class="text-sm text-n-slate-11">
          {{ t('CRM_DEALS.FILTERS.NO_OPTIONS') }}
        </span>
        <Button
          :label="t('CRM_DEALS.FILTERS.APPLY')"
          sm
          :disabled="!canApply"
          @click="apply"
        />
      </div>
    </div>
  </div>
</template>
