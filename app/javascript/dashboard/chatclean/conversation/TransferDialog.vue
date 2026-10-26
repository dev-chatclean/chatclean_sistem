<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ChatcleanConversationsAPI from 'dashboard/api/chatclean/conversations';

// Transferir o atendimento para um departamento e/ou atendente (US 15). Só aparecem os
// atendentes com acesso ao canal (FA 15.2); a observação vira nota interna de quem transferiu.
const props = defineProps({
  conversationId: { type: Number, required: true },
  inboxId: { type: Number, required: true },
});

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const isLoading = ref(false);
const form = reactive({ teamId: '', assigneeId: '', note: '' });

const teams = useMapGetter('teams/getTeams');
const assignableAgents = useMapGetter('inboxAssignableAgents/getAssignableAgents');

const teamOptions = computed(() => [
  { value: '', label: t('CHATCLEAN.TRANSFER.NO_TEAM') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const agentOptions = computed(() => [
  { value: '', label: t('CHATCLEAN.TRANSFER.NO_AGENT') },
  ...assignableAgents
    .value(props.inboxId)
    .map(agent => ({ value: agent.id, label: agent.name })),
]);
const canSubmit = computed(() => Boolean(form.teamId || form.assigneeId));

const open = () => {
  Object.assign(form, { teamId: '', assigneeId: '', note: '' });
  store.dispatch('inboxAssignableAgents/fetch', [props.inboxId]);
  dialogRef.value?.open();
};

const handleConfirm = async () => {
  isLoading.value = true;
  try {
    await ChatcleanConversationsAPI.transfer(props.conversationId, {
      teamId: form.teamId || null,
      assigneeId: form.assigneeId || null,
      note: form.note,
    });
    useAlert(t('CHATCLEAN.TRANSFER.SUCCESS'));
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CHATCLEAN.TRANSFER.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CHATCLEAN.TRANSFER.TITLE')"
    :description="t('CHATCLEAN.TRANSFER.DESCRIPTION')"
    :confirm-button-label="t('CHATCLEAN.TRANSFER.CONFIRM')"
    :disable-confirm-button="!canSubmit"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CHATCLEAN.TRANSFER.TEAM_LABEL') }}
        <Select
          v-model="form.teamId"
          :options="teamOptions"
          data-test="transfer-team"
        />
      </label>
      <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
        {{ t('CHATCLEAN.TRANSFER.AGENT_LABEL') }}
        <Select
          v-model="form.assigneeId"
          :options="agentOptions"
          data-test="transfer-agent"
        />
      </label>
      <TextArea
        v-model="form.note"
        :label="t('CHATCLEAN.TRANSFER.NOTE_LABEL')"
        :placeholder="t('CHATCLEAN.TRANSFER.NOTE_PLACEHOLDER')"
        data-test="transfer-note"
      />
    </div>
  </Dialog>
</template>
