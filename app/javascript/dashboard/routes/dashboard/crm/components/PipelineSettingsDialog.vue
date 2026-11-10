<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmSettingsAPI from 'dashboard/api/crm/settings';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import PipelineTab from './settings/PipelineTab.vue';
import LeadEntryTab from './settings/LeadEntryTab.vue';
import CardTab from './settings/CardTab.vue';
import { useItemLabel } from '../useItemLabel';
import {
  DEFAULT_LOST_COLOR,
  DEFAULT_STALE_AFTER_DAYS,
  DEFAULT_WON_COLOR,
  ITEM_LABEL_CUSTOM_MAX_LENGTH,
  MAX_STALE_DAYS,
  PIPELINE_GROUP_MAX_LENGTH,
  PIPELINE_NAME_MAX_LENGTH,
  SETTINGS_TABS,
  STAGE_NAME_MAX_LENGTH,
  STAGE_NAME_MIN_LENGTH,
} from '../constants';

const props = defineProps({
  hasDefaultPipeline: { type: Boolean, default: false },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();
const { itemLabel } = useItemLabel();

const dialogRef = ref(null);
const isSaving = ref(false);
const activeTab = ref('pipeline');
const pipeline = ref(null);
const form = ref({});
const closingStages = ref([]);
const openStages = ref([]);
const cardFields = ref([]);
const settings = ref(null);

const isEditing = computed(() => Boolean(pipeline.value));

const tabs = computed(() =>
  SETTINGS_TABS.map(key => ({
    key,
    label: t(`CRM_PIPELINES.SETTINGS_TABS.${key.toUpperCase()}`),
  }))
);

const dialogTitle = computed(() => {
  if (!isEditing.value) return t('CRM_PIPELINES.FORM.CREATE_TITLE');
  return t(
    `CRM_PIPELINES.SETTINGS_TABS.TITLES.${activeTab.value.toUpperCase()}`
  );
});

const tooLong = (value, max) =>
  String(value || '').trim().length > max
    ? t('CRM_PIPELINES.FORM.NAME.TOO_LONG', { max })
    : '';

const stageNameError = value => {
  const length = String(value || '').trim().length;
  if (length >= STAGE_NAME_MIN_LENGTH && length <= STAGE_NAME_MAX_LENGTH) {
    return '';
  }
  return t('CRM_PIPELINES.FORM.STAGE_NAME_LENGTH', {
    min: STAGE_NAME_MIN_LENGTH,
    max: STAGE_NAME_MAX_LENGTH,
  });
};

const errors = computed(() => {
  const result = {
    name: tooLong(form.value.name, PIPELINE_NAME_MAX_LENGTH),
    group_name: tooLong(form.value.group_name, PIPELINE_GROUP_MAX_LENGTH),
    item_label_custom:
      form.value.item_label === 'custom'
        ? tooLong(form.value.item_label_custom, ITEM_LABEL_CUSTOM_MAX_LENGTH)
        : '',
  };
  const days = Number(form.value.stale_after_days);
  if (!Number.isInteger(days) || days < 1 || days > MAX_STALE_DAYS) {
    result.stale_after_days = t('CRM_PIPELINES.FORM.STALE_DAYS.INVALID', {
      max: MAX_STALE_DAYS,
    });
  }
  closingStages.value.forEach(stage => {
    result[stage.stage_type] = stageNameError(stage.name);
  });
  return result;
});

const isInvalid = computed(
  () =>
    !form.value.name?.trim() ||
    (form.value.item_label === 'custom' &&
      !form.value.item_label_custom?.trim()) ||
    Object.values(errors.value).some(Boolean)
);

const buildForm = source => ({
  name: source?.name ?? '',
  description: source?.description ?? '',
  group_name: source?.group_name ?? '',
  pipeline_type: source?.pipeline_type ?? 'sales',
  item_label: source?.item_label ?? 'deal',
  item_label_custom: source?.item_label_custom ?? '',
  stale_after_days: source?.stale_after_days ?? DEFAULT_STALE_AFTER_DAYS,
  one_card_per_contact: source?.one_card_per_contact ?? true,
});

const buildClosingStages = source => {
  if (source) {
    return source.stages
      .filter(stage => ['won', 'lost'].includes(stage.stage_type))
      .map(stage => ({ ...stage }));
  }
  return [
    {
      stage_type: 'won',
      name: t('CRM_PIPELINES.FORM.WON.DEFAULT_NAME'),
      color: DEFAULT_WON_COLOR,
    },
    {
      stage_type: 'lost',
      name: t('CRM_PIPELINES.FORM.LOST.DEFAULT_NAME'),
      color: DEFAULT_LOST_COLOR,
    },
  ];
};

const loadSettings = async () => {
  try {
    const { data } = await CrmSettingsAPI.get();
    settings.value = {
      autoCreateDeals: data.auto_create_deals,
      leadEntry: {
        ...data.lead_entry,
        alert_after_days: data.lead_entry.alert_after_days ?? '',
      },
    };
  } catch (error) {
    useAlert(t('CRM_PIPELINES.API.FETCH_ERROR'));
  }
};

const open = (source = null, tab = 'pipeline') => {
  pipeline.value = source;
  activeTab.value = source ? tab : 'pipeline';
  form.value = buildForm(source);
  closingStages.value = buildClosingStages(source);
  openStages.value = (source?.stages || []).filter(
    stage => !['won', 'lost'].includes(stage.stage_type)
  );
  cardFields.value = [...(source?.card_fields || [])];
  settings.value = null;
  if (source) loadSettings();
  dialogRef.value?.open();
};

const formPayload = () => ({
  ...form.value,
  name: form.value.name.trim(),
  stale_after_days: Number(form.value.stale_after_days),
  card_fields: cardFields.value,
});

const saveClosingStages = async () => {
  const original = pipeline.value.stages;
  const changed = closingStages.value.filter(stage => {
    const before = original.find(item => item.id === stage.id);
    return before.name !== stage.name.trim() || before.color !== stage.color;
  });
  await Promise.all(
    changed.map(stage =>
      CrmPipelinesAPI.updateStage(pipeline.value.id, stage.id, {
        name: stage.name.trim(),
        color: stage.color,
      })
    )
  );
};

const saveStageOrder = async () => {
  const before = pipeline.value.stages
    .filter(stage => !['won', 'lost'].includes(stage.stage_type))
    .map(stage => stage.id);
  const after = openStages.value.map(stage => stage.id);
  if (before.join() === after.join()) return;
  await CrmPipelinesAPI.reorderStages(pipeline.value.id, after);
};

const saveSettings = async () => {
  if (!settings.value) return;
  const { alert_after_days: alertDays, ...leadEntry } =
    settings.value.leadEntry;
  await CrmSettingsAPI.update({
    auto_create_deals: settings.value.autoCreateDeals,
    lead_entry: {
      ...leadEntry,
      alert_after_days: alertDays === '' ? null : Number(alertDays),
    },
  });
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  try {
    let saved;
    if (isEditing.value) {
      await CrmPipelinesAPI.update(pipeline.value.id, {
        pipeline: formPayload(),
      });
      await saveClosingStages();
      await saveStageOrder();
      await saveSettings();
      saved = pipeline.value;
      useAlert(t('CRM_PIPELINES.API.UPDATE_SUCCESS'));
    } else {
      const [won, lost] = closingStages.value;
      const { data } = await CrmPipelinesAPI.create({
        pipeline: {
          ...formPayload(),
          won_stage: { name: won.name.trim(), color: won.color },
          lost_stage: { name: lost.name.trim(), color: lost.color },
        },
      });
      saved = data;
      useAlert(t('CRM_PIPELINES.API.CREATE_SUCCESS'));
    }
    dialogRef.value?.close();
    emit('saved', saved);
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :confirm-button-label="
      isEditing ? t('CRM_PIPELINES.FORM.SAVE') : t('CRM_PIPELINES.FORM.CREATE')
    "
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="isInvalid"
    :is-loading="isSaving"
    overflow-y-auto
    @confirm="save"
  >
    <div class="flex flex-col gap-5">
      <TabBar
        v-if="isEditing"
        :tabs="tabs"
        :initial-active-tab="SETTINGS_TABS.indexOf(activeTab)"
        @tab-changed="activeTab = $event.key"
      />
      <PipelineTab
        v-show="activeTab === 'pipeline'"
        v-model:form="form"
        v-model:closing-stages="closingStages"
        v-model:open-stages="openStages"
        :is-editing="isEditing"
        :errors="errors"
      />
      <template v-if="isEditing && activeTab === 'lead_entry'">
        <LeadEntryTab
          v-if="settings"
          v-model:auto-create-deals="settings.autoCreateDeals"
          v-model:lead-entry="settings.leadEntry"
          :has-default-pipeline="props.hasDefaultPipeline"
        />
      </template>
      <CardTab
        v-if="isEditing && activeTab === 'card'"
        v-model="cardFields"
        :item-label="itemLabel(form)"
      />
    </div>
  </Dialog>
</template>
