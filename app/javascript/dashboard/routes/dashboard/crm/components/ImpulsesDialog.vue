<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmImpulsesAPI from 'dashboard/api/crm/impulses';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  IMPULSE_DELAY_UNITS,
  IMPULSE_MAX_DELAY_MINUTES,
  IMPULSE_MAX_STEPS,
  IMPULSE_NAME_MAX_LENGTH,
  IMPULSE_VARIABLES,
} from '../constants';

const { t } = useI18n();
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const templatesFor = useMapGetter('inboxes/getFilteredWhatsAppTemplates');

const SELECT_CLASS =
  'reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12';
const PLACEHOLDER_PATTERN = /{{\s*([^}]+?)\s*}}/g;

const dialogRef = ref(null);
const pipeline = ref(null);
const stage = ref(null);
const impulses = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const editing = ref(null);
const pendingDeleteId = ref(null);

const templateOptions = inboxId => (inboxId ? templatesFor.value(inboxId) : []);

const findTemplate = step =>
  templateOptions(step.inboxId).find(
    item =>
      item.name === step.templateName && item.language === step.templateLanguage
  );

const templateBody = template =>
  template?.components?.find(component => component.type === 'BODY')?.text ||
  '';

const templatePlaceholders = template => [
  ...new Set(
    [...templateBody(template).matchAll(PLACEHOLDER_PATTERN)].map(
      match => match[1]
    )
  ),
];

// The template is chosen from a WhatsApp inbox; at send time it is looked up in the conversation's inbox.
const inboxWithTemplate = (name, language) =>
  whatsAppInboxes.value.find(inbox =>
    templatesFor
      .value(inbox.id)
      .some(item => item.name === name && item.language === language)
  )?.id ?? whatsAppInboxes.value[0]?.id;

const toDelay = minutes => {
  const unit = ['DAYS', 'HOURS'].find(
    key => minutes && minutes % IMPULSE_DELAY_UNITS[key] === 0
  );
  const key = unit || 'MINUTES';
  return { amount: minutes / IMPULSE_DELAY_UNITS[key], unit: key };
};

const buildStep = (step = {}) => {
  const params = step.template_params || {};
  return {
    id: step.id,
    ...toDelay(step.delay_minutes ?? 0),
    messageType: step.message_type || 'text',
    content: step.content || '',
    inboxId: inboxWithTemplate(params.name, params.language),
    templateName: params.name || '',
    templateLanguage: params.language || '',
    templateCategory: params.category || '',
    body: { ...(params.processed_params?.body || {}) },
  };
};

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

const selectTemplate = (step, key) => {
  const [name, language] = key.split('|');
  const template = templateOptions(step.inboxId).find(
    item => item.name === name && item.language === language
  );
  step.templateName = name;
  step.templateLanguage = language;
  step.templateCategory = template?.category || '';
  step.body = Object.fromEntries(
    templatePlaceholders(template).map(placeholder => [placeholder, ''])
  );
};

const delayMinutes = step =>
  Number(step.amount) * IMPULSE_DELAY_UNITS[step.unit];

const stepError = step => {
  const minutes = delayMinutes(step);
  if (!Number.isInteger(minutes) || minutes < 0) {
    return t('CRM_PIPELINES.IMPULSES.ERRORS.DELAY');
  }
  if (minutes > IMPULSE_MAX_DELAY_MINUTES) {
    return t('CRM_PIPELINES.IMPULSES.ERRORS.DELAY_MAX');
  }
  if (step.messageType === 'text' && !step.content.trim()) {
    return t('CRM_PIPELINES.IMPULSES.ERRORS.CONTENT');
  }
  if (step.messageType === 'template') {
    if (!step.templateName) return t('CRM_PIPELINES.IMPULSES.ERRORS.TEMPLATE');
    if (Object.values(step.body).some(value => !value.trim())) {
      return t('CRM_PIPELINES.IMPULSES.ERRORS.VARIABLES');
    }
  }
  return '';
};

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
  message_type: step.messageType,
  content: step.messageType === 'text' ? step.content.trim() : null,
  template_params:
    step.messageType === 'template'
      ? {
          name: step.templateName,
          language: step.templateLanguage,
          category: step.templateCategory,
          processed_params: { body: step.body },
        }
      : {},
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

        <div class="flex flex-col gap-1.5">
          <span class="text-sm text-n-slate-12">
            {{ t('CRM_PIPELINES.IMPULSES.TYPE.LABEL') }}
          </span>
          <select v-model="step.messageType" :class="SELECT_CLASS">
            <option value="text">
              {{ t('CRM_PIPELINES.IMPULSES.TYPE.TEXT') }}
            </option>
            <option value="template" :disabled="!whatsAppInboxes.length">
              {{ t('CRM_PIPELINES.IMPULSES.TYPE.TEMPLATE') }}
            </option>
          </select>
          <span class="text-label-small text-n-slate-11">
            {{
              step.messageType === 'text'
                ? t('CRM_PIPELINES.IMPULSES.TYPE.TEXT_HINT')
                : t('CRM_PIPELINES.IMPULSES.TYPE.TEMPLATE_HINT')
            }}
          </span>
        </div>

        <TextArea
          v-if="step.messageType === 'text'"
          v-model="step.content"
          :label="t('CRM_PIPELINES.IMPULSES.CONTENT')"
          :max-length="4096"
          auto-height
        />

        <template v-else>
          <label class="flex flex-col gap-1.5">
            <span class="text-sm text-n-slate-12">
              {{ t('CRM_PIPELINES.IMPULSES.TEMPLATE.INBOX') }}
            </span>
            <select v-model="step.inboxId" :class="SELECT_CLASS">
              <option
                v-for="inbox in whatsAppInboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </label>
          <label class="flex flex-col gap-1.5">
            <span class="text-sm text-n-slate-12">
              {{ t('CRM_PIPELINES.IMPULSES.TEMPLATE.LABEL') }}
            </span>
            <select
              :value="
                step.templateName
                  ? `${step.templateName}|${step.templateLanguage}`
                  : ''
              "
              :class="SELECT_CLASS"
              @change="selectTemplate(step, $event.target.value)"
            >
              <option value="" disabled>
                {{ t('CRM_PIPELINES.IMPULSES.TEMPLATE.CHOOSE') }}
              </option>
              <option
                v-for="template in templateOptions(step.inboxId)"
                :key="`${template.name}|${template.language}`"
                :value="`${template.name}|${template.language}`"
              >
                {{ `${template.name} (${template.language})` }}
              </option>
            </select>
          </label>
          <p
            v-if="findTemplate(step)"
            class="px-3 py-2 m-0 text-sm rounded-lg bg-n-alpha-black2 text-n-slate-12 whitespace-pre-wrap"
          >
            {{ templateBody(findTemplate(step)) }}
          </p>
          <Input
            v-for="(_, key) in step.body"
            :key="key"
            v-model="step.body[key]"
            :label="t('CRM_PIPELINES.IMPULSES.TEMPLATE.VARIABLE', { key })"
            :placeholder="IMPULSE_VARIABLES[0]"
          />
        </template>

        <span class="text-label-small text-n-slate-11">
          {{
            t('CRM_PIPELINES.IMPULSES.VARIABLES', {
              variables: IMPULSE_VARIABLES.join(' '),
            })
          }}
        </span>
        <span v-if="stepError(step)" class="text-label-small text-n-ruby-11">
          {{ stepError(step) }}
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
