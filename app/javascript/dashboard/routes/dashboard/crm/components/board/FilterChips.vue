<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  filters: { type: Array, required: true },
});

const emit = defineEmits(['remove']);

const { t } = useI18n();

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
  <span
    v-for="filter in filters"
    :key="filter.field"
    class="flex items-center gap-1.5 h-9 ps-3 pe-1.5 text-sm rounded-xl bg-n-brand/10 text-n-slate-12"
  >
    <span class="text-n-slate-11">{{ filter.label }}:</span>
    {{ filterChipText(filter) }}
    <button
      type="button"
      class="flex items-center justify-center rounded-md size-6 hover:bg-n-alpha-2"
      :aria-label="t('CRM_DEALS.FILTERS.REMOVE')"
      @click="emit('remove', filter)"
    >
      <span class="i-lucide-x size-3.5" />
    </button>
  </span>
</template>
