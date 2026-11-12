<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDateTime } from './dealTime';

const props = defineProps({
  events: { type: Array, default: () => [] },
});

const { t, locale } = useI18n();

const items = computed(() => [...props.events].reverse());

const eventKey = event => {
  if (event.event_type === 'created' && event.data.conversation)
    return 'CREATED_FROM_CONVERSATION';
  if (event.event_type === 'custom_field_changed') {
    if (event.data.source === 'ai') return 'CUSTOM_FIELD_AI';
    if (event.data.from === undefined) return 'CUSTOM_FIELD_SET';
    if (event.data.to === undefined) return 'CUSTOM_FIELD_CLEARED';
  }
  return event.event_type.toUpperCase();
};

const eventText = event =>
  t(`CRM_DEALS.DETAIL.EVENTS.${eventKey(event)}`, {
    user: event.user_name || t('CRM_DEALS.DETAIL.SYSTEM'),
    from: event.from_stage_name || event.data.from,
    to: event.to_stage_name || event.data.to,
    conversation: event.data.conversation,
    activity: event.data.activity,
    file: event.data.file,
    field: event.data.field,
    category: event.data.category
      ? t(`CRM_DEALS.FILES.CATEGORIES.${event.data.category.toUpperCase()}`)
      : '',
    impulse: event.data.impulse,
    campaign: event.data.campaign,
    step: event.data.step,
    reason: event.data.reason
      ? t(`CRM_DEALS.IMPULSES.REASONS.${event.data.reason.toUpperCase()}`)
      : '',
  });
</script>

<template>
  <ol class="flex flex-col gap-4 p-0 m-0 list-none">
    <li
      v-for="event in items"
      :key="event.id"
      class="flex items-start justify-between gap-3 text-sm"
    >
      <span class="flex items-start gap-2.5 text-n-slate-12">
        <span class="mt-0.5 i-lucide-history size-4 text-n-slate-10 shrink-0" />
        {{ eventText(event) }}
      </span>
      <span class="text-n-slate-11 shrink-0">
        {{ formatDateTime(event.created_at, locale) }}
      </span>
    </li>
  </ol>
</template>
