<script setup>
import { useI18n } from 'vue-i18n';
import { AI_TEMPERATURE_STYLES } from '../../constants';

defineProps({
  temperature: { type: String, required: true },
  reason: { type: String, default: '' },
});

const { t } = useI18n();
</script>

<template>
  <span
    v-tooltip.top="reason"
    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-md text-label-small shrink-0"
    :class="AI_TEMPERATURE_STYLES[temperature].classes"
  >
    <span class="size-3.5" :class="AI_TEMPERATURE_STYLES[temperature].icon" />
    {{ t(`CRM_DEALS.AI.TEMPERATURE.${temperature.toUpperCase()}`) }}
  </span>
</template>
