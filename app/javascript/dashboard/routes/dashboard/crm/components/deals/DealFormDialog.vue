<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ContactPicker from './ContactPicker.vue';
import { isClosingStage } from '../../dealHelpers';

const props = defineProps({
  pipeline: { type: Object, default: null },
  itemLabel: { type: String, required: true },
});

const emit = defineEmits(['created']);

const TITLE_MAX_LENGTH = 120;

const { t } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');
const agents = useMapGetter('agents/getAgents');

const dialogRef = ref(null);
const isSaving = ref(false);
const contact = ref(null);
const form = ref({});

const openStages = computed(() =>
  (props.pipeline?.stages || []).filter(stage => !isClosingStage(stage))
);
const showValue = computed(
  () => props.pipeline?.pipeline_type !== 'management'
);
const titleRequired = computed(() => !contact.value);
const isInvalid = computed(
  () =>
    !form.value.stage_id ||
    (titleRequired.value && !form.value.title?.trim()) ||
    (form.value.title?.length || 0) > TITLE_MAX_LENGTH ||
    Number(form.value.value) < 0
);

const open = ({ stageId = null, contact: initialContact = null } = {}) => {
  contact.value = initialContact;
  form.value = {
    title: '',
    value: '',
    stage_id: stageId || openStages.value[0]?.id,
    expected_close_date: '',
    assignee_id: currentUser.value.id,
  };
  dialogRef.value?.open();
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  try {
    const { data } = await CrmDealsAPI.create({
      deal: {
        stage_id: form.value.stage_id,
        contact_id: contact.value?.id || null,
        title: form.value.title.trim() || null,
        value: Number(form.value.value) || 0,
        expected_close_date: form.value.expected_close_date || null,
        assignee_id: form.value.assignee_id,
      },
    });
    useAlert(t('CRM_DEALS.API.CREATE_SUCCESS', { item: props.itemLabel }));
    dialogRef.value?.close();
    emit('created', data);
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
    :title="t('CRM_DEALS.FORM.TITLE', { item: itemLabel })"
    :confirm-button-label="t('CRM_DEALS.FORM.CREATE', { item: itemLabel })"
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="isInvalid"
    :is-loading="isSaving"
    overflow-y-auto
    @confirm="save"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1.5">
        <div class="flex items-center justify-between">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.FORM.CONTACT') }}
          </span>
          <span class="text-label-small text-n-slate-10">
            {{ t('CRM_DEALS.FORM.OPTIONAL') }}
          </span>
        </div>
        <ContactPicker v-model="contact" />
      </div>

      <div class="flex flex-col gap-1.5">
        <div class="flex items-center justify-between">
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.FORM.DEAL_TITLE') }}
          </span>
          <span
            class="text-label-small"
            :class="titleRequired ? 'text-n-amber-11' : 'text-n-slate-10'"
          >
            {{
              titleRequired
                ? t('CRM_DEALS.FORM.TITLE_REQUIRED')
                : t('CRM_DEALS.FORM.OPTIONAL')
            }}
          </span>
        </div>
        <Input
          v-model="form.title"
          :placeholder="t('CRM_DEALS.FORM.TITLE_PLACEHOLDER')"
        />
      </div>

      <div class="grid grid-cols-2 gap-3">
        <Input
          v-if="showValue"
          v-model="form.value"
          type="number"
          min="0"
          :label="t('CRM_DEALS.FORM.VALUE')"
          placeholder="0,00"
        />
        <label
          class="flex flex-col gap-1.5"
          :class="{ 'col-span-2': !showValue }"
        >
          <span class="text-label text-n-slate-12">
            {{ t('CRM_DEALS.FORM.STAGE') }}
          </span>
          <select
            v-model="form.stage_id"
            class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          >
            <option
              v-for="stage in openStages"
              :key="stage.id"
              :value="stage.id"
            >
              {{ stage.name }}
            </option>
          </select>
        </label>
      </div>

      <Input
        v-model="form.expected_close_date"
        type="date"
        :label="t('CRM_DEALS.FORM.EXPECTED_CLOSE_DATE')"
      />

      <label class="flex flex-col gap-1.5">
        <span class="text-label text-n-slate-12">
          {{ t('CRM_DEALS.FORM.ASSIGNEE') }}
        </span>
        <select
          v-model="form.assignee_id"
          :disabled="!isAdmin"
          class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 disabled:opacity-70"
        >
          <option
            v-for="agent in isAdmin ? agents : [currentUser]"
            :key="agent.id"
            :value="agent.id"
          >
            {{ agent.available_name || agent.name }}
          </option>
        </select>
      </label>
    </div>
  </Dialog>
</template>
