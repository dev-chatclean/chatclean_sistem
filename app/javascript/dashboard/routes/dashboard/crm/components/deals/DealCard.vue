<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import { daysInStage, formatCurrency, staleLevel } from '../../dealHelpers';
import { ACTIVITY_TYPES } from '../../constants';
import { formatShortDateTime } from './detail/dealTime';

const props = defineProps({
  deal: { type: Object, required: true },
  stage: { type: Object, default: null },
  pipeline: { type: Object, default: null },
  showValue: { type: Boolean, default: true },
});

const emit = defineEmits(['open', 'move']);

const { t, locale } = useI18n();

const nextActivity = computed(() => props.deal.next_activity);
const nextActivityIcon = computed(
  () =>
    ACTIVITY_TYPES.find(
      type => type.value === nextActivity.value?.activity_type
    )?.icon
);
const nextActivityOverdue = computed(
  () => nextActivity.value && nextActivity.value.due_at * 1000 < Date.now()
);

const showExpectedClose = computed(
  () =>
    props.deal.expected_close_date &&
    props.pipeline?.card_fields?.includes('expected_close_date')
);
const expectedCloseText = computed(() => {
  if (!props.deal.expected_close_date) return '';
  const [year, month, day] = props.deal.expected_close_date.split('-');
  return `${day}/${month}/${year}`;
});

const stale = computed(() => staleLevel(props.deal, props.stage));
const staleClass = computed(
  () =>
    ({
      warning: 'border-n-amber-8',
      danger: 'border-n-ruby-8',
    })[stale.value] || 'border-n-weak'
);
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="relative flex flex-col gap-2.5 p-3 border rounded-xl cursor-grab bg-n-solid-2 hover:bg-n-solid-3 group/card"
    :class="staleClass"
    @click="emit('open', deal)"
    @keydown.enter="emit('open', deal)"
  >
    <div class="flex items-start gap-2">
      <span
        class="flex items-center justify-center rounded-lg size-9 shrink-0 bg-n-alpha-2 text-n-slate-11"
      >
        <span class="i-lucide-briefcase size-4" />
      </span>
      <div class="flex flex-col flex-1 min-w-0 gap-1">
        <span class="text-sm font-semibold text-n-slate-12 truncate">
          {{ deal.display_name }}
        </span>
        <span
          v-if="!deal.contact"
          class="self-start px-1.5 py-0.5 rounded-md text-label-small border border-n-slate-6 text-n-slate-11"
        >
          {{ t('CRM_DEALS.CARD.NO_CONTACT') }}
        </span>
      </div>
      <div class="flex items-center gap-1 shrink-0">
        <Button
          v-tooltip.top="t('CRM_DEALS.MENU.MOVE')"
          icon="i-lucide-arrow-left-right"
          slate
          ghost
          xs
          class="opacity-0 group-hover/card:opacity-100 focus:opacity-100"
          :aria-label="t('CRM_DEALS.MENU.MOVE')"
          @click.stop="emit('move', deal)"
        />
        <span class="text-label-small text-n-slate-10">{{
          t('CRM_DEALS.NUMBER', { number: deal.number })
        }}</span>
      </div>
    </div>
    <div
      class="flex flex-wrap items-center gap-x-3 gap-y-1 text-label-small text-n-slate-11"
    >
      <span class="flex items-center gap-1 min-w-0">
        <span class="i-lucide-user size-3.5 shrink-0" />
        <span class="truncate">{{ deal.assignee.name }}</span>
      </span>
      <span v-if="showValue" class="flex items-center gap-1 font-medium">
        <span class="i-lucide-banknote size-3.5" />
        {{ formatCurrency(deal.value) }}
      </span>
    </div>
    <span
      v-if="nextActivity"
      class="flex items-center gap-1 min-w-0 text-label-small"
      :class="nextActivityOverdue ? 'text-n-ruby-11' : 'text-n-slate-11'"
    >
      <span class="size-3.5 shrink-0" :class="nextActivityIcon" />
      <span class="truncate">{{ nextActivity.title }}</span>
      <span class="shrink-0">
        · {{ formatShortDateTime(nextActivity.due_at, locale) }}
      </span>
      <span v-if="nextActivityOverdue" class="font-medium shrink-0">
        · {{ t('CRM_DEALS.CARD.NEXT_ACTIVITY_OVERDUE') }}
      </span>
    </span>
    <span
      v-if="showExpectedClose"
      class="flex items-center gap-1 text-label-small text-n-slate-11"
    >
      <span class="i-lucide-calendar-check size-3.5" />
      {{ expectedCloseText }}
    </span>
    <span
      class="flex items-center gap-1 text-label-small"
      :class="{
        'text-n-amber-11': stale === 'warning',
        'text-n-ruby-11': stale === 'danger',
        'text-n-slate-11': !stale,
      }"
    >
      <span class="i-lucide-clock size-3.5" />
      {{ t('CRM_DEALS.CARD.IN_STAGE', { days: daysInStage(deal) }) }}
    </span>
  </div>
</template>
