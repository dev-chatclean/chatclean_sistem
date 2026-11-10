<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import { CARD_FIELDS, MAX_CARD_FIELDS } from '../../constants';

defineProps({
  itemLabel: { type: String, required: true },
});

const cardFields = defineModel({ type: Array, required: true });

const { t } = useI18n();

const isFull = computed(() => cardFields.value.length >= MAX_CARD_FIELDS);

const toggle = (field, checked) => {
  cardFields.value = checked
    ? [...cardFields.value, field]
    : cardFields.value.filter(item => item !== field);
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <span class="text-label-small text-n-slate-11">
      {{ t('CRM_PIPELINES.CARD.HINT', { max: MAX_CARD_FIELDS }) }}
    </span>

    <div class="flex flex-col gap-1.5 p-3 border rounded-xl border-n-slate-6">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CRM_PIPELINES.CARD.PREVIEW.CONTACT') }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.CARD.PREVIEW.NUMBER') }}
        </span>
      </div>
      <div class="flex items-center gap-4 text-label-small text-n-slate-11">
        <span class="flex items-center gap-1">
          <span class="i-lucide-user size-3.5" />
          {{ t('CRM_PIPELINES.CARD.PREVIEW.OWNER') }}
        </span>
        <span class="flex items-center gap-1">
          <span class="i-lucide-banknote size-3.5" />
          {{ t('CRM_PIPELINES.CARD.PREVIEW.VALUE') }}
        </span>
      </div>
      <span class="flex items-center gap-1 text-label-small text-n-slate-11">
        <span class="i-lucide-clock size-3.5" />
        {{ t('CRM_PIPELINES.CARD.PREVIEW.IN_STAGE') }}
      </span>
      <span
        v-for="field in cardFields"
        :key="field"
        class="flex items-center gap-1 text-label-small text-n-slate-11"
      >
        <span class="i-lucide-plus size-3.5" />
        {{ t(`CRM_PIPELINES.CARD.FIELDS.${field.toUpperCase()}`) }}
      </span>
    </div>

    <div class="flex items-center justify-between">
      <span class="flex items-center gap-1.5 text-label text-n-slate-12">
        <span class="i-lucide-credit-card size-4" />
        {{ t('CRM_PIPELINES.CARD.ITEMS', { item: itemLabel }) }}
      </span>
      <span
        class="px-2 py-0.5 rounded-full text-label-small border border-n-slate-6 text-n-slate-11"
      >
        {{ cardFields.length }}/{{ CARD_FIELDS.length }}
      </span>
    </div>
    <label
      v-for="field in CARD_FIELDS"
      :key="field"
      class="flex items-start gap-2 px-3 py-2 rounded-lg"
      :class="cardFields.includes(field) ? 'bg-n-brand/10' : ''"
    >
      <Checkbox
        class="mt-0.5"
        :model-value="cardFields.includes(field)"
        :disabled="isFull && !cardFields.includes(field)"
        @update:model-value="toggle(field, $event)"
      />
      <span class="flex flex-col">
        <span class="text-sm text-n-slate-12">
          {{ t(`CRM_PIPELINES.CARD.FIELDS.${field.toUpperCase()}`) }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.CARD.ONLY_WHEN_FILLED') }}
        </span>
      </span>
    </label>
  </div>
</template>
