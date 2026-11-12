<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmImpulsesAPI from 'dashboard/api/crm/impulses';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ClientMessageEditor from './ClientMessageEditor.vue';
import { useClientMessage } from '../useClientMessage';
import {
  IMPULSE_DELAY_UNITS,
  IMPULSE_MAX_DELAY_MINUTES,
  IMPULSE_MAX_STEPS,
  IMPULSE_NAME_MAX_LENGTH,
  IMPULSE_VARIABLES,
} from '../constants';

const { t } = useI18n();
const { buildMessage, messageError, messagePayload } = useClientMessage();

const SELECT_CLASS =
  'reset-base h-10 ps-3 pe-6 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12';

const dialogRef = ref(null);
const pipeline = ref(null);
const stage = ref(null);
const impulses = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const editing = ref(null);
const pendingDeleteId = ref(null);

const toDelay = minutes => {
  const unit = ['DAYS', 'HOURS'].find(
    key => minutes && minutes % IMPULSE_DELAY_UNITS[key] === 0
  );
  const key = unit || 'MINUTES';
  return { amount: minutes / IMPULSE_DELAY_UNITS[key], unit: key };
};

const buildStep = (step = {}) => ({
  id: step.id,
  ...toDelay(step.delay_minutes ?? 0),
  message: buildMessage(step),
});

const fetchImpulses = async () => {
  isLoading.value = true;
  try {
    const { data } = await CrmImpulsesAPI.list(
      pipeline.value.id,
      stage.value.id
    );
    impulses.value = data.payload;
  } finally {
    isLoading.value = false;
  }
};

const open = ({ pipeline: source, stage: target }) => {
  pipeline.value = source;
  stage.value = target;
  editing.value = null;
  impulses.value = [];
  dialogRef.value?.open();
  fetchImpulses();
};

const startEdit = (impulse = null) => {
  editing.value = {
    id: impulse?.id,
    name: impulse?.name ?? '',
    active: impulse?.active ?? true,
    stop_on_reply: impulse?.stop_on_reply ?? true,
    steps: impulse ? impulse.steps.map(buildStep) : [buildStep()],
    removedStepIds: [],
  };
};

const addStep = () => {
  if (editing.value.steps.length >= IMPULSE_MAX_STEPS) return;
  editing.value.steps.push(
    buildStep({ delay_minutes: IMPULSE_DELAY_UNITS.DAYS })
  );
};

const removeStep = index => {
  const [step] = editing.value.steps.splice(index, 1);
  if (step.id) editing.value.removedStepIds.push(step.id);
};

const delayMinutes = step =>
  Number(step.amount) * IMPULSE_DELAY_UNITS[step.unit];

const delayError = step => {
  const minutes = delayMinutes(step);
  if (!Number.isInteger(minutes) || minutes < 0) {
    return t('CRM_PIPELINES.IMPULSES.ERRORS.DELAY');
  }
  if (minutes > IMPULSE_MAX_DELAY_MINUTES) {
    return t('CRM_PIPELINES.IMPULSES.ERRORS.DELAY_MAX');
  }
  return '';
};

const stepError = step => delayError(step) || messageError(step.message);

const nameError = computed(() =>
  editing.value?.name.trim().length > IMPULSE_NAME_MAX_LENGTH
    ? t('CRM_PIPELINES.IMPULSES.ERRORS.NAME', { max: IMPULSE_NAME_MAX_LENGTH })
    : ''
);

const isInvalid = computed(
  () =>
    !editing.value?.name.trim() ||
    Boolean(nameError.value) ||
    editing.value.steps.some(step => Boolean(stepError(step)))
);

const stepPayload = step => ({
  id: step.id,
  delay_minutes: delayMinutes(step),
  ...messagePayload(step.message),
});

const showError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  const { id, name, active, stop_on_reply: stopOnReply } = editing.value;
  const payload = {
    name: name.trim(),
    active,
    stop_on_reply: stopOnReply,
    steps_attributes: [
      ...editing.value.steps.map(stepPayload),
      ...editing.value.removedStepIds.map(stepId => ({
        id: stepId,
        _destroy: true,
      })),
    ],
  };
  try {
    if (id) {
      await CrmImpulsesAPI.updateImpulse(
        pipeline.value.id,
        stage.value.id,
        id,
        payload
      );
    } else {
      await CrmImpulsesAPI.createImpulse(
        pipeline.value.id,
        stage.value.id,
        payload
      );
    }
    useAlert(t('CRM_PIPELINES.IMPULSES.API.SAVE_SUCCESS'));
    editing.value = null;
    await fetchImpulses();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const toggleActive = async impulse => {
  try {
    await CrmImpulsesAPI.updateImpulse(
      pipeline.value.id,
      stage.value.id,
      impulse.id,
      { active: !impulse.active }
    );
    await fetchImpulses();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.SAVE_ERROR');
  }
};

const removeImpulse = async impulse => {
  if (pendingDeleteId.value !== impulse.id) {
    pendingDeleteId.value = impulse.id;
    return;
  }
  pendingDeleteId.value = null;
  try {
    await CrmImpulsesAPI.deleteImpulse(
      pipeline.value.id,
      stage.value.id,
      impulse.id
    );
    useAlert(t('CRM_PIPELINES.IMPULSES.API.DELETE_SUCCESS'));
    await fetchImpulses();
  } catch (error) {
    showError(error, 'CRM_PIPELINES.API.DELETE_ERROR');
  }
};

const delayText = minutes => {
  if (!minutes) return t('CRM_PIPELINES.IMPULSES.DELAY.NOW');
  const { amount, unit } = toDelay(minutes);
  return t(
    `CRM_PIPELINES.IMPULSES.DELAY.AFTER_${unit}`,
    { count: amount },
    amount
  );
};

const impulseSummary = impulse =>
  [
    t(
      'CRM_PIPELINES.IMPULSES.STEPS_COUNT',
      { count: impulse.steps.length },
      impulse.steps.length
    ),
    impulse.steps.map(step => delayText(step.delay_minutes)).join(' → '),
  ].join(' · ');

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CRM_PIPELINES.IMPULSES.TITLE', { stage: stage?.name })"
    :description="t('CRM_PIPELINES.IMPULSES.DESCRIPTION')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    width="2xl"
    overflow-y-auto
  >
    <div v-if="!editing" class="flex flex-col gap-3">
      <span v-if="isLoading" class="text-sm text-n-slate-11">
        {{ t('CRM_PIPELINES.IMPULSES.LOADING') }}
      </span>
      <div
        v-else-if="!impulses.length"
        class="px-3 py-2.5 text-sm border rounded-lg border-n-slate-6 text-n-slate-11"
      >
        {{ t('CRM_PIPELINES.IMPULSES.EMPTY') }}
      </div>
      <div
        v-for="impulse in impulses"
        :key="impulse.id"
        class="flex items-center justify-between gap-3 px-3 py-2.5 border rounded-lg border-n-slate-6"
      >
        <div class="flex flex-col min-w-0 gap-0.5">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ impulse.name }}
          </span>
          <span class="text-label-small text-n-slate-11 truncate">
            {{ impulseSummary(impulse) }}
          </span>
        </div>
        <div class="flex items-center gap-1 shrink-0">
          <Switch
            :model-value="impulse.active"
            :aria-label="t('CRM_PIPELINES.IMPULSES.ACTIVE')"
            @update:model-value="toggleActive(impulse)"
          />
          <Button
            icon="i-lucide-pencil"
            slate
            ghost
            xs
            :aria-label="t('CRM_PIPELINES.IMPULSES.EDIT')"
            @click="startEdit(impulse)"
          />
          <Button
            icon="i-lucide-trash-2"
            :label="
              pendingDeleteId === impulse.id
                ? t('CRM_PIPELINES.IMPULSES.CONFIRM_DELETE')
                : ''
            "
            ruby
            ghost
            xs
            :aria-label="t('CRM_PIPELINES.IMPULSES.DELETE')"
            @click="removeImpulse(impulse)"
          />
        </div>
      </div>
      <span class="text-label-small text-n-slate-11">
        {{ t('CRM_PIPELINES.IMPULSES.ENTRY_HINT') }}
      </span>
    </div>

    <div v-else class="flex flex-col gap-5">
      <Input
        v-model="editing.name"
        :label="t('CRM_PIPELINES.IMPULSES.NAME.LABEL')"
        :placeholder="t('CRM_PIPELINES.IMPULSES.NAME.PLACEHOLDER')"
        :message="nameError"
        :message-type="nameError ? 'error' : 'info'"
        autofocus
      />
      <label class="flex items-start gap-3 text-sm text-n-slate-12">
        <Switch v-model="editing.active" class="mt-0.5" />
        {{ t('CRM_PIPELINES.IMPULSES.ACTIVE') }}
      </label>
      <label class="flex items-start gap-3 text-sm text-n-slate-12">
        <Switch v-model="editing.stop_on_reply" class="mt-0.5" />
        {{ t('CRM_PIPELINES.IMPULSES.STOP_ON_REPLY') }}
      </label>

      <div
        v-for="(step, index) in editing.steps"
        :key="step.id || `new-${index}`"
        class="flex flex-col gap-3 p-3 border rounded-lg border-n-slate-6"
      >
        <div class="flex items-center justify-between gap-2">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_PIPELINES.IMPULSES.STEP', { number: index + 1 }) }}
          </span>
          <Button
            v-if="editing.steps.length > 1"
            icon="i-lucide-x"
            slate
            ghost
            xs
            :aria-label="t('CRM_PIPELINES.IMPULSES.REMOVE_STEP')"
            @click="removeStep(index)"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <span class="text-sm text-n-slate-12">
            {{
              index === 0
                ? t('CRM_PIPELINES.IMPULSES.DELAY.FIRST')
                : t('CRM_PIPELINES.IMPULSES.DELAY.NEXT')
            }}
          </span>
          <div class="flex items-start gap-2">
            <Input v-model="step.amount" type="number" min="0" class="w-24" />
            <select v-model="step.unit" :class="SELECT_CLASS">
              <option
                v-for="(_, unit) in IMPULSE_DELAY_UNITS"
                :key="unit"
                :value="unit"
              >
                {{ t(`CRM_PIPELINES.IMPULSES.DELAY.UNITS.${unit}`) }}
              </option>
            </select>
          </div>
        </div>

        <ClientMessageEditor
          v-model="step.message"
          :variables="IMPULSE_VARIABLES"
        />
        <span v-if="delayError(step)" class="text-label-small text-n-ruby-11">
          {{ delayError(step) }}
        </span>
      </div>

      <Button
        v-if="editing.steps.length < IMPULSE_MAX_STEPS"
        :label="t('CRM_PIPELINES.IMPULSES.ADD_STEP')"
        icon="i-lucide-plus"
        slate
        faded
        sm
        class="self-start"
        @click="addStep"
      />
    </div>

    <template #footer>
      <div class="flex items-center justify-end w-full gap-2">
        <template v-if="!editing">
          <Button
            :label="t('CRM_PIPELINES.IMPULSES.CLOSE')"
            slate
            faded
            sm
            @click="dialogRef?.close()"
          />
          <Button
            :label="t('CRM_PIPELINES.IMPULSES.NEW')"
            icon="i-lucide-plus"
            sm
            @click="startEdit()"
          />
        </template>
        <template v-else>
          <Button
            :label="t('CRM_PIPELINES.FORM.CANCEL')"
            slate
            faded
            sm
            @click="editing = null"
          />
          <Button
            :label="t('CRM_PIPELINES.IMPULSES.SAVE')"
            sm
            :is-loading="isSaving"
            :disabled="isInvalid"
            @click="save"
          />
        </template>
      </div>
    </template>
  </Dialog>
</template>
