<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
  // Erro da API, como nome repetido: aparece no campo de nome.
  errorMessage: { type: String, default: '' },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const teams = useMapGetter('teams/getTeams');
const dialogRef = ref(null);
// Motivo em edição; null ao criar.
const closingReason = ref(null);
// Recria a seleção de departamentos a cada abertura.
const openCount = ref(0);
const form = reactive({
  name: '',
  closingMessage: '',
  askSaleValue: false,
  teamIds: [],
  isActive: true,
});

const teamOptions = computed(() =>
  teams.value.map(team => ({ value: team.id, label: team.name }))
);

const open = (record = null) => {
  closingReason.value = record;
  Object.assign(form, {
    name: record?.name || '',
    closingMessage: record?.closing_message || '',
    askSaleValue: record?.ask_sale_value || false,
    teamIds: record?.team_ids || [],
    isActive: record ? record.is_active : true,
  });
  openCount.value += 1;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const handleConfirm = () => {
  if (!form.name.trim()) return;
  emit('submit', {
    id: closingReason.value?.id,
    attributes: {
      name: form.name.trim(),
      closing_message: form.closingMessage.trim() || null,
      ask_sale_value: form.askSaleValue,
      team_ids: form.teamIds,
      is_active: form.isActive,
    },
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      closingReason
        ? t('CHATCLEAN.CLOSING_REASONS.DIALOG.EDIT_TITLE')
        : t('CHATCLEAN.CLOSING_REASONS.DIALOG.CREATE_TITLE')
    "
    :confirm-button-label="t('CHATCLEAN.CLOSING_REASONS.DIALOG.SAVE')"
    :cancel-button-label="t('CHATCLEAN.CLOSING_REASONS.DIALOG.CANCEL')"
    :disable-confirm-button="!form.name.trim()"
    :is-loading="isLoading"
    overflow-y-auto
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="t('CHATCLEAN.CLOSING_REASONS.DIALOG.NAME')"
        :message="errorMessage"
        :message-type="errorMessage ? 'error' : 'info'"
        data-test="reason-name"
      />
      <TextArea
        v-model="form.closingMessage"
        :label="t('CHATCLEAN.CLOSING_REASONS.DIALOG.CLOSING_MESSAGE')"
        :placeholder="
          t('CHATCLEAN.CLOSING_REASONS.DIALOG.CLOSING_MESSAGE_PLACEHOLDER')
        "
        data-test="reason-message"
      />
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CHATCLEAN.CLOSING_REASONS.DIALOG.TEAMS') }}
        <TagMultiSelectComboBox
          :key="openCount"
          v-model="form.teamIds"
          :options="teamOptions"
          :placeholder="t('CHATCLEAN.CLOSING_REASONS.DIALOG.TEAMS_PLACEHOLDER')"
          data-test="reason-teams"
        />
      </label>
      <div class="flex items-center justify-between text-sm text-n-slate-12">
        {{ t('CHATCLEAN.CLOSING_REASONS.DIALOG.ASK_SALE_VALUE') }}
        <Switch v-model="form.askSaleValue" data-test="reason-sale-value" />
      </div>
      <div class="flex items-center justify-between text-sm text-n-slate-12">
        {{ t('CHATCLEAN.CLOSING_REASONS.DIALOG.ACTIVE') }}
        <Switch v-model="form.isActive" data-test="reason-active" />
      </div>
    </div>
  </Dialog>
</template>
