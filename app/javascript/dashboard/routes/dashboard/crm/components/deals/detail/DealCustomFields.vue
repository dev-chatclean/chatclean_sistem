<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['update']);

const { t } = useI18n();
const attributesByModel = useMapGetter('attributes/getAttributesByModel');

const NUMBER_TYPES = ['number', 'currency', 'percent'];
const INPUT_CLASS =
  'reset-base h-11 w-44 px-3 text-base rounded-xl border border-n-slate-6 bg-transparent text-n-slate-12';

const fields = computed(() => attributesByModel.value('deal_attribute'));

const valueOf = key => props.deal.custom_attributes?.[key] ?? '';

const save = (attribute, raw) => {
  const value =
    NUMBER_TYPES.includes(attribute.attribute_display_type) && raw !== ''
      ? Number(raw)
      : raw;
  if (value === valueOf(attribute.attribute_key)) return;
  emit('update', { custom_attributes: { [attribute.attribute_key]: value } });
};
</script>

<template>
  <template v-if="fields.length">
    <label
      v-for="attribute in fields"
      :key="attribute.attribute_key"
      class="flex items-center justify-between gap-3"
    >
      <span class="text-base truncate text-n-slate-11">
        {{ attribute.attribute_display_name }}
      </span>
      <input
        v-if="attribute.attribute_display_type === 'checkbox'"
        type="checkbox"
        class="size-4"
        :checked="valueOf(attribute.attribute_key) === true"
        @change="save(attribute, $event.target.checked)"
      />
      <select
        v-else-if="attribute.attribute_display_type === 'list'"
        :value="valueOf(attribute.attribute_key)"
        :class="INPUT_CLASS"
        @change="save(attribute, $event.target.value)"
      >
        <option value="">{{ t('CRM_DEALS.CUSTOM_FIELDS.CHOOSE') }}</option>
        <option
          v-for="option in attribute.attribute_values"
          :key="option"
          :value="option"
        >
          {{ option }}
        </option>
      </select>
      <input
        v-else
        :type="
          attribute.attribute_display_type === 'date'
            ? 'date'
            : NUMBER_TYPES.includes(attribute.attribute_display_type)
              ? 'number'
              : 'text'
        "
        :value="valueOf(attribute.attribute_key)"
        :class="INPUT_CLASS"
        @change="save(attribute, $event.target.value.trim())"
      />
    </label>
  </template>
</template>
