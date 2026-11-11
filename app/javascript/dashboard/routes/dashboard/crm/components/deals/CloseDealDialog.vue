<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { LOSS_REASONS, WIN_REASONS } from '../../constants';

const props = defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm', 'cancel']);

const { t } = useI18n();

const dialogRef = ref(null);
const outcome = ref('won');
const deal = ref(null);
const stage = ref(null);
const reason = ref('');
const note = ref('');
let confirmed = false;

const isWon = computed(() => outcome.value === 'won');
const reasons = computed(() => (isWon.value ? WIN_REASONS : LOSS_REASONS));
const canConfirm = computed(() => isWon.value || Boolean(reason.value));

const open = ({ deal: target, stage: targetStage }) => {
  deal.value = target;
  stage.value = targetStage;
  outcome.value = targetStage.stage_type;
  reason.value = isWon.value ? 'not_informed' : '';
  note.value = '';
  confirmed = false;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const confirm = () => {
  if (!canConfirm.value || props.isLoading) return;
  confirmed = true;
  emit('confirm', {
    deal: deal.value,
    stage: stage.value,
    close_reason: reason.value,
    close_note: note.value.trim() || null,
  });
};

const onClose = () => {
  if (!confirmed) emit('cancel');
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isWon ? t('CRM_DEALS.CLOSE.WIN_TITLE') : t('CRM_DEALS.CLOSE.LOSE_TITLE')
    "
    :description="deal ? `#${deal.number} · ${deal.display_name}` : ''"
    :confirm-button-label="
      isWon
        ? t('CRM_DEALS.CLOSE.WIN_CONFIRM')
        : t('CRM_DEALS.CLOSE.LOSE_CONFIRM')
    "
    :cancel-button-label="t('CRM_PIPELINES.FORM.CANCEL')"
    :disable-confirm-button="!canConfirm"
    :is-loading="props.isLoading"
    @confirm="confirm"
    @close="onClose"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-1.5">
        <span class="text-label text-n-slate-12">
          {{
            isWon
              ? t('CRM_DEALS.CLOSE.WIN_REASON')
              : t('CRM_DEALS.CLOSE.LOSE_REASON')
          }}
        </span>
        <select
          v-model="reason"
          class="reset-base h-10 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
        >
          <option v-if="!isWon" value="" disabled>
            {{ t('CRM_DEALS.CLOSE.CHOOSE_REASON') }}
          </option>
          <option v-for="item in reasons" :key="item" :value="item">
            {{ t(`CRM_DEALS.REASONS.${item.toUpperCase()}`) }}
          </option>
        </select>
      </label>
      <TextArea
        v-model="note"
        :label="t('CRM_DEALS.CLOSE.NOTE')"
        :placeholder="
          isWon
            ? t('CRM_DEALS.CLOSE.WIN_NOTE_PLACEHOLDER')
            : t('CRM_DEALS.CLOSE.LOSE_NOTE_PLACEHOLDER')
        "
        :max-length="1000"
      />
    </div>
  </Dialog>
</template>
