<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { LEAD_ORIGINS, LEAD_SOURCES, MAX_STALE_DAYS } from '../../constants';

defineProps({
  hasDefaultPipeline: { type: Boolean, default: false },
});

const autoCreateDeals = defineModel('autoCreateDeals', {
  type: Boolean,
  required: true,
});
const leadEntry = defineModel('leadEntry', { type: Object, required: true });

const { t } = useI18n();
const inboxes = useMapGetter('inboxes/getInboxes');

const allInboxes = computed({
  get: () => !leadEntry.value.inbox_ids.length,
  set: value => {
    leadEntry.value.inbox_ids = value
      ? []
      : inboxes.value.map(inbox => inbox.id);
  },
});

const toggleItem = (key, value, checked) => {
  const items = leadEntry.value[key];
  leadEntry.value[key] = checked
    ? [...items, value]
    : items.filter(item => item !== value);
};

const lists = computed(() => [
  {
    key: 'origins',
    icon: 'i-lucide-map-pin',
    title: t('CRM_PIPELINES.LEAD_ENTRY.ORIGINS'),
    options: LEAD_ORIGINS,
  },
  {
    key: 'sources',
    icon: 'i-lucide-message-square',
    title: t('CRM_PIPELINES.LEAD_ENTRY.SOURCES'),
    options: LEAD_SOURCES,
  },
]);
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex items-start gap-3 p-4 border rounded-xl border-n-slate-6">
      <Switch
        v-model="autoCreateDeals"
        :disabled="!hasDefaultPipeline"
        class="mt-0.5"
      />
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CRM_PIPELINES.LEAD_ENTRY.TOGGLE') }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.LEAD_ENTRY.DESCRIPTION') }}
        </span>
        <span
          v-if="!hasDefaultPipeline"
          class="text-label-small text-n-amber-11"
        >
          {{ t('CRM_PIPELINES.LEAD_ENTRY.NEEDS_DEFAULT') }}
        </span>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <span class="flex items-center gap-1.5 text-label text-n-slate-12">
        <span class="i-lucide-radio-tower size-4" />
        {{ t('CRM_PIPELINES.LEAD_ENTRY.CHANNELS') }}
      </span>
      <label class="flex items-center gap-2 text-sm text-n-slate-12">
        <Checkbox v-model="allInboxes" />
        {{ t('CRM_PIPELINES.LEAD_ENTRY.ALL_CHANNELS') }}
      </label>
      <template v-if="!allInboxes">
        <label
          v-for="inbox in inboxes"
          :key="inbox.id"
          class="flex items-center gap-2 text-sm text-n-slate-12 ps-6"
        >
          <Checkbox
            :model-value="leadEntry.inbox_ids.includes(inbox.id)"
            @update:model-value="toggleItem('inbox_ids', inbox.id, $event)"
          />
          {{ inbox.name }}
        </label>
      </template>
    </div>

    <div v-for="list in lists" :key="list.key" class="flex flex-col gap-2">
      <div class="flex items-center justify-between">
        <span class="flex items-center gap-1.5 text-label text-n-slate-12">
          <span class="size-4" :class="list.icon" />
          {{ list.title }}
        </span>
        <span
          class="px-2 py-0.5 rounded-full text-label-small border border-n-slate-6 text-n-slate-11"
        >
          {{ leadEntry[list.key].length }}/{{ list.options.length }}
        </span>
      </div>
      <label
        v-for="option in list.options"
        :key="option"
        class="flex items-center gap-2 px-3 rounded-lg h-9 text-sm text-n-slate-12"
        :class="leadEntry[list.key].includes(option) ? 'bg-n-brand/10' : ''"
      >
        <Checkbox
          :model-value="leadEntry[list.key].includes(option)"
          @update:model-value="toggleItem(list.key, option, $event)"
        />
        {{ t(`CRM_PIPELINES.LEAD_ENTRY.OPTIONS.${option.toUpperCase()}`) }}
      </label>
    </div>

    <span class="text-label-small text-n-slate-11">
      {{ t('CRM_PIPELINES.LEAD_ENTRY.LISTS_HINT') }}
    </span>

    <div class="flex flex-col gap-2">
      <Input
        v-model="leadEntry.alert_after_days"
        type="number"
        min="1"
        :max="String(MAX_STALE_DAYS)"
        :label="t('CRM_PIPELINES.LEAD_ENTRY.ALERT_DAYS.LABEL')"
      />
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.LEAD_ENTRY.ALERT_DAYS.HINT') }}
      </span>
    </div>
  </div>
</template>
