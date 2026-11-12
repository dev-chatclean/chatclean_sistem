<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import StageColorPicker from './StageColorPicker.vue';
import {
  MAX_REQUIRED_TASKS,
  MAX_STALE_DAYS,
  STAGE_COLORS,
  STAGE_DEAL_REQUIREMENTS,
  STAGE_NAME_MAX_LENGTH,
  STAGE_NAME_MIN_LENGTH,
  TASK_TITLE_MAX_LENGTH,
} from '../constants';

const emit = defineEmits(['saved', 'delete']);

const { t } = useI18n();
const labels = useMapGetter('labels/getLabels');
const attributesByModel = useMapGetter('attributes/getAttributesByModel');
const dealAttributes = computed(() =>
  attributesByModel.value('deal_attribute')
);

const dialogRef = ref(null);
const requirementsRef = ref(null);
const isSaving = ref(false);
const pipeline = ref(null);
const stage = ref(null);
const afterStageId = ref(null);
const form = ref({});
const newTask = ref('');

const isEditing = computed(() => Boolean(stage.value));
const isClosing = computed(() =>
  ['won', 'lost'].includes(stage.value?.stage_type)
);

const nameError = computed(() => {
  const length = form.value.name?.trim().length || 0;
  if (
    !length ||
    (length >= STAGE_NAME_MIN_LENGTH && length <= STAGE_NAME_MAX_LENGTH)
  ) {
    return '';
  }
  return t('CRM_PIPELINES.FORM.STAGE_NAME_LENGTH', {
    min: STAGE_NAME_MIN_LENGTH,
    max: STAGE_NAME_MAX_LENGTH,
  });
});

const staleError = computed(() => {
  if (isClosing.value) return '';
  const days = Number(form.value.stale_after_days);
  return Number.isInteger(days) && days >= 1 && days <= MAX_STALE_DAYS
    ? ''
    : t('CRM_PIPELINES.FORM.STALE_DAYS.INVALID', { max: MAX_STALE_DAYS });
});

const isInvalid = computed(
  () => !form.value.name?.trim() || Boolean(nameError.value || staleError.value)
);

const open = ({
  pipeline: source,
  stage: target = null,
  after = null,
  focusRequirements = false,
}) => {
  pipeline.value = source;
  stage.value = target;
  afterStageId.value = after;
  newTask.value = '';
  const requirements = target?.requirements || {};
  form.value = {
    name: target?.name ?? '',
    color: target?.color ?? STAGE_COLORS[0],
    stale_after_days: target?.stale_after_days ?? source.stale_after_days,
    requirements: {
      require_owner: requirements.require_owner ?? false,
      require_expected_close_date:
        requirements.require_expected_close_date ?? false,
      require_positive_value: requirements.require_positive_value ?? false,
      require_product: requirements.require_product ?? false,
      require_document: requirements.require_document ?? false,
      required_custom_fields: requirements.required_custom_fields ?? [],
      required_tasks: [...(requirements.required_tasks ?? [])],
      apply_labels: [...(requirements.apply_labels ?? [])],
    },
  };
  dialogRef.value?.open();
  if (focusRequirements) {
    nextTick(() =>
      requestAnimationFrame(() =>
        requirementsRef.value?.scrollIntoView({ block: 'start' })
      )
    );
  }
};

const toggleLabel = title => {
  const current = form.value.requirements.apply_labels;
  form.value.requirements.apply_labels = current.includes(title)
    ? current.filter(item => item !== title)
    : [...current, title];
};

const toggleRequiredField = (key, checked) => {
  const fields = form.value.requirements.required_custom_fields;
  form.value.requirements.required_custom_fields = checked
    ? [...fields, key]
    : fields.filter(field => field !== key);
};

const addTask = () => {
  const title = newTask.value.trim();
  const tasks = form.value.requirements.required_tasks;
  if (!title || tasks.length >= MAX_REQUIRED_TASKS) return;
  form.value.requirements.required_tasks = [
    ...tasks,
    title.slice(0, TASK_TITLE_MAX_LENGTH),
  ];
  newTask.value = '';
};

const removeTask = index => {
  form.value.requirements.required_tasks =
    form.value.requirements.required_tasks.filter((_, i) => i !== index);
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  const payload = {
    name: form.value.name.trim(),
    color: form.value.color,
    requirements: form.value.requirements,
  };
  if (!isClosing.value) {
    payload.stale_after_days = Number(form.value.stale_after_days);
  }
  try {
    if (isEditing.value) {
      await CrmPipelinesAPI.updateStage(
        pipeline.value.id,
        stage.value.id,
        payload
      );
      useAlert(t('CRM_PIPELINES.STAGE.API.UPDATE_SUCCESS'));
    } else {
      await CrmPipelinesAPI.createStage(
        pipeline.value.id,
        payload,
        afterStageId.value
      );
      useAlert(t('CRM_PIPELINES.STAGE.API.CREATE_SUCCESS'));
    }
    dialogRef.value?.close();
    emit('saved');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

const requestDelete = () => {
  dialogRef.value?.close();
  emit('delete', stage.value);
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('CRM_PIPELINES.STAGE.EDIT_TITLE')
        : t('CRM_PIPELINES.STAGE.CREATE_TITLE')
    "
    :show-confirm-button="false"
    :show-cancel-button="false"
    overflow-y-auto
  >
    <div class="flex flex-col gap-5">
      <Input
        v-model="form.name"
        :label="t('CRM_PIPELINES.STAGE.NAME.LABEL')"
        :placeholder="t('CRM_PIPELINES.STAGE.NAME.PLACEHOLDER')"
        :message="nameError"
        :message-type="nameError ? 'error' : 'info'"
        autofocus
      />

      <div class="flex flex-col gap-2">
        <span class="text-label text-n-slate-12">
          {{ t('CRM_PIPELINES.STAGE.COLOR') }}
        </span>
        <StageColorPicker v-model="form.color" />
      </div>

      <div v-if="isEditing && !isClosing" class="flex flex-col gap-2">
        <Input
          v-model="form.stale_after_days"
          type="number"
          min="1"
          :max="String(MAX_STALE_DAYS)"
          :label="t('CRM_PIPELINES.STAGE.STALE_DAYS.LABEL')"
          :message="staleError"
          :message-type="staleError ? 'error' : 'info'"
        />
        <span class="text-label-small text-n-slate-11">
          {{ t('CRM_PIPELINES.STAGE.STALE_DAYS.HINT') }}
        </span>
      </div>

      <div
        ref="requirementsRef"
        class="flex flex-col gap-4 pt-4 border-t border-n-slate-6"
      >
        <span class="text-label-small text-n-slate-11 uppercase">
          {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.TITLE') }}
        </span>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.OWNER.LABEL') }}
          </span>
          <label class="flex items-start gap-3 text-sm text-n-slate-12">
            <Switch v-model="form.requirements.require_owner" class="mt-0.5" />
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.OWNER.HINT') }}
          </label>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.CUSTOM_FIELDS.LABEL') }}
          </span>
          <template v-if="dealAttributes.length">
            <label
              v-for="attribute in dealAttributes"
              :key="attribute.attribute_key"
              class="flex items-center gap-2 text-sm text-n-slate-12"
            >
              <Checkbox
                :model-value="
                  form.requirements.required_custom_fields.includes(
                    attribute.attribute_key
                  )
                "
                @update:model-value="
                  toggleRequiredField(attribute.attribute_key, $event)
                "
              />
              {{ attribute.attribute_display_name }}
            </label>
          </template>
          <div
            v-else
            class="px-3 py-2.5 text-sm border rounded-lg border-n-slate-6 text-n-slate-11"
          >
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.CUSTOM_FIELDS.EMPTY') }}
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.DEAL.LABEL') }}
          </span>
          <label
            v-for="key in STAGE_DEAL_REQUIREMENTS"
            :key="key"
            class="flex items-center gap-2 text-sm text-n-slate-12"
          >
            <Checkbox v-model="form.requirements[key]" />
            {{
              t(`CRM_PIPELINES.STAGE.REQUIREMENTS.DEAL.${key.toUpperCase()}`)
            }}
          </label>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.TASKS.LABEL') }}
          </span>
          <span class="text-label-small text-n-slate-11">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.TASKS.HINT') }}
          </span>
          <div
            v-for="(task, index) in form.requirements.required_tasks"
            :key="`${task}-${index}`"
            class="flex items-center justify-between gap-2 px-3 border rounded-lg h-9 border-n-slate-6 text-sm text-n-slate-12"
          >
            <span class="flex items-center gap-2 truncate">
              <span class="i-lucide-square-check size-4 text-n-slate-10" />
              {{ task }}
            </span>
            <Button
              icon="i-lucide-x"
              slate
              ghost
              xs
              :aria-label="t('CRM_PIPELINES.STAGE.REQUIREMENTS.TASKS.REMOVE')"
              @click="removeTask(index)"
            />
          </div>
          <div class="flex items-center gap-2">
            <Input
              v-model="newTask"
              class="flex-1"
              :placeholder="
                t('CRM_PIPELINES.STAGE.REQUIREMENTS.TASKS.PLACEHOLDER')
              "
              @enter.prevent="addTask"
            />
            <Button
              :label="t('CRM_PIPELINES.STAGE.REQUIREMENTS.TASKS.ADD')"
              icon="i-lucide-plus"
              slate
              faded
              sm
              :disabled="!newTask.trim()"
              @click="addTask"
            />
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.LABELS.LABEL') }}
          </span>
          <div v-if="labels.length" class="flex flex-wrap gap-2">
            <button
              v-for="label in labels"
              :key="label.id"
              type="button"
              class="flex items-center gap-1.5 px-2.5 py-1 text-label-small rounded-md outline outline-1 -outline-offset-1"
              :class="
                form.requirements.apply_labels.includes(label.title)
                  ? 'outline-n-brand bg-n-brand/10 text-n-blue-11'
                  : 'outline-n-slate-6 text-n-slate-12'
              "
              @click="toggleLabel(label.title)"
            >
              <span
                class="rounded-full size-2"
                :style="{ backgroundColor: label.color }"
              />
              {{ label.title }}
            </button>
          </div>
          <span v-else class="text-sm text-n-slate-11">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.LABELS.EMPTY') }}
          </span>
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.DOCUMENT.LABEL') }}
          </span>
          <label class="flex items-start gap-3 text-sm text-n-slate-12">
            <Switch
              v-model="form.requirements.require_document"
              class="mt-0.5"
            />
            {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.DOCUMENT.HINT') }}
          </label>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          v-if="isEditing && stage.stage_type === 'custom'"
          :label="t('CRM_PIPELINES.STAGE.DELETE')"
          icon="i-lucide-trash-2"
          ruby
          faded
          sm
          @click="requestDelete"
        />
        <span v-else />
        <div class="flex items-center gap-2">
          <Button
            :label="t('CRM_PIPELINES.FORM.CANCEL')"
            slate
            faded
            sm
            @click="dialogRef?.close()"
          />
          <Button
            :label="
              isEditing
                ? t('CRM_PIPELINES.STAGE.SAVE')
                : t('CRM_PIPELINES.STAGE.CREATE')
            "
            sm
            :is-loading="isSaving"
            :disabled="isInvalid"
            @click="save"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
