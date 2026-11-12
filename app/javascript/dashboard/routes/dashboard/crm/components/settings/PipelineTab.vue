<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import StageColorPicker from '../StageColorPicker.vue';
import ChoiceChips from './ChoiceChips.vue';
import {
  ITEM_LABELS,
  MAX_STALE_DAYS,
  PIPELINE_DESCRIPTION_MAX_LENGTH,
  PIPELINE_TYPES,
} from '../../constants';

const props = defineProps({
  isEditing: { type: Boolean, default: false },
  errors: { type: Object, default: () => ({}) },
});

const form = defineModel('form', { type: Object, required: true });
const closingStages = defineModel('closingStages', {
  type: Array,
  required: true,
});
const openStages = defineModel('openStages', {
  type: Array,
  default: () => [],
});

const { t } = useI18n();

const typeOptions = computed(() =>
  PIPELINE_TYPES.map(value => ({
    value,
    label: t(`CRM_PIPELINES.FORM.TYPE.${value.toUpperCase()}`),
  }))
);

const itemLabelOptions = computed(() =>
  ITEM_LABELS.map(value => ({
    value,
    label: t(`CRM_PIPELINES.FORM.ITEM_LABEL.OPTIONS.${value.toUpperCase()}`),
  }))
);

const initialStage = computed(() =>
  openStages.value.find(stage => stage.stage_type === 'initial')
);
const customStages = computed({
  get: () => openStages.value.filter(stage => stage.stage_type === 'custom'),
  set: stages => {
    openStages.value = [initialStage.value, ...stages].filter(Boolean);
  },
});
</script>

<template>
  <div class="flex flex-col gap-5">
    <Input
      v-model="form.name"
      :label="t('CRM_PIPELINES.FORM.NAME.LABEL')"
      :placeholder="t('CRM_PIPELINES.FORM.NAME.PLACEHOLDER')"
      :message="props.errors.name"
      :message-type="props.errors.name ? 'error' : 'info'"
      autofocus
    />

    <TextArea
      v-model="form.description"
      :label="t('CRM_PIPELINES.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CRM_PIPELINES.FORM.DESCRIPTION.PLACEHOLDER')"
      :max-length="PIPELINE_DESCRIPTION_MAX_LENGTH"
    />

    <Input
      v-model="form.group_name"
      :label="t('CRM_PIPELINES.FORM.GROUP.LABEL')"
      :placeholder="t('CRM_PIPELINES.FORM.GROUP.PLACEHOLDER')"
      :message="props.errors.group_name"
      :message-type="props.errors.group_name ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-2">
      <span class="text-label text-n-slate-12">
        {{ t('CRM_PIPELINES.FORM.TYPE.LABEL') }}
      </span>
      <div
        v-if="props.isEditing"
        class="flex items-center gap-1.5 text-sm text-n-slate-12"
      >
        <span class="i-lucide-lock size-3.5 text-n-slate-10" />
        {{ t(`CRM_PIPELINES.FORM.TYPE.${form.pipeline_type.toUpperCase()}`) }}
      </div>
      <ChoiceChips v-else v-model="form.pipeline_type" :options="typeOptions" />
      <span class="text-label-small text-n-slate-11">
        {{
          props.isEditing
            ? t('CRM_PIPELINES.FORM.TYPE.LOCKED')
            : t(
                `CRM_PIPELINES.FORM.TYPE.${form.pipeline_type.toUpperCase()}_HINT`
              )
        }}
      </span>
    </div>

    <div class="flex flex-col gap-2">
      <span class="text-label text-n-slate-12">
        {{ t('CRM_PIPELINES.FORM.ITEM_LABEL.LABEL') }}
      </span>
      <ChoiceChips v-model="form.item_label" :options="itemLabelOptions" />
      <Input
        v-if="form.item_label === 'custom'"
        v-model="form.item_label_custom"
        :placeholder="t('CRM_PIPELINES.FORM.ITEM_LABEL.CUSTOM_PLACEHOLDER')"
        :message="props.errors.item_label_custom"
        :message-type="props.errors.item_label_custom ? 'error' : 'info'"
      />
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.FORM.ITEM_LABEL.HINT') }}
      </span>
    </div>

    <div class="flex flex-col gap-2">
      <Input
        v-model="form.stale_after_days"
        type="number"
        min="1"
        :max="String(MAX_STALE_DAYS)"
        :label="t('CRM_PIPELINES.FORM.STALE_DAYS.LABEL')"
        :message="props.errors.stale_after_days"
        :message-type="props.errors.stale_after_days ? 'error' : 'info'"
      />
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.FORM.STALE_DAYS.HINT') }}
      </span>
    </div>

    <div class="flex items-start gap-3 p-3 border rounded-xl border-n-slate-6">
      <Switch v-model="form.one_card_per_contact" class="mt-0.5" />
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CRM_PIPELINES.FORM.ONE_CARD.LABEL') }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.FORM.ONE_CARD.HINT') }}
        </span>
      </div>
    </div>

    <div v-if="props.isEditing" class="flex flex-col gap-2">
      <span class="text-label text-n-slate-12">
        {{ t('CRM_PIPELINES.FORM.STAGES.LABEL') }}
      </span>
      <div
        v-if="initialStage"
        class="flex items-center gap-2 px-3 border rounded-lg h-9 border-n-slate-6 text-sm text-n-slate-12"
      >
        <span class="i-lucide-lock size-3.5 text-n-slate-10" />
        <span
          class="rounded-full size-2"
          :style="{ backgroundColor: initialStage.color }"
        />
        {{ initialStage.name }}
      </div>
      <Draggable
        v-model="customStages"
        item-key="id"
        handle=".drag-handle"
        class="flex flex-col gap-2"
      >
        <template #item="{ element }">
          <div
            class="flex items-center gap-2 px-3 border rounded-lg h-9 border-n-slate-6 text-sm text-n-slate-12 bg-n-solid-2"
          >
            <span
              class="drag-handle i-lucide-grip-vertical size-4 cursor-grab text-n-slate-10"
            />
            <span
              class="rounded-full size-2"
              :style="{ backgroundColor: element.color }"
            />
            {{ element.name }}
          </div>
        </template>
      </Draggable>
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.FORM.STAGES.HINT') }}
      </span>
    </div>

    <div class="flex flex-col gap-3">
      <span class="text-label text-n-slate-12">
        {{ t('CRM_PIPELINES.FORM.CLOSING_STAGES') }}
      </span>
      <div
        v-for="stage in closingStages"
        :key="stage.stage_type"
        class="flex flex-col gap-3 p-3 border rounded-xl border-n-slate-6"
      >
        <Input
          v-model="stage.name"
          :label="
            t(`CRM_PIPELINES.FORM.${stage.stage_type.toUpperCase()}.LABEL`)
          "
          :message="props.errors[stage.stage_type]"
          :message-type="props.errors[stage.stage_type] ? 'error' : 'info'"
        />
        <StageColorPicker v-model="stage.color" />
      </div>
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.FORM.CLOSING_STAGES_HINT') }}
      </span>
    </div>
  </div>
</template>
