<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ChatcleanConversationsAPI from 'dashboard/api/chatclean/conversations';
import TransferDialog from './TransferDialog.vue';

// Ações do cabeçalho do atendimento na ChatClean (US 15): Aceitar no pendente (sem atendente),
// Fila no ativo (volta para os pendentes) e Transferir. "Fechar" continua sendo o do Chatwoot.
const props = defineProps({
  chat: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();
const transferDialogRef = ref(null);
const isWorking = ref(false);

const hasAssignee = computed(() => Boolean(props.chat.meta?.assignee));
// Atendimento fechado: sem Aceitar e Fila; "Reabrir" é o botão do Chatwoot e Transferir continua.
const isClosed = computed(() => props.chat.status === 'resolved');

const run = async (action, successMessage) => {
  isWorking.value = true;
  try {
    await action();
    useAlert(successMessage);
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CHATCLEAN.QUEUE.ERROR'));
  } finally {
    isWorking.value = false;
  }
};

const accept = () =>
  run(async () => {
    const { data } = await ChatcleanConversationsAPI.accept(props.chat.id);
    store.dispatch('setCurrentChatAssignee', {
      conversationId: props.chat.id,
      assignee: data,
    });
  }, t('CHATCLEAN.QUEUE.ACCEPTED'));

const sendToQueue = () =>
  run(
    () =>
      store.dispatch('assignAgent', {
        conversationId: props.chat.id,
        agentId: null,
      }),
    t('CHATCLEAN.QUEUE.SENT_TO_QUEUE')
  );
</script>

<template>
  <div class="flex items-center gap-2">
    <Button
      v-if="!isClosed && !hasAssignee"
      :label="t('CHATCLEAN.QUEUE.ACCEPT')"
      icon="i-lucide-check"
      size="sm"
      :is-loading="isWorking"
      data-test="conversation-accept"
      @click="accept"
    />
    <Button
      v-else-if="!isClosed"
      :label="t('CHATCLEAN.QUEUE.SEND_TO_QUEUE')"
      icon="i-lucide-list-start"
      size="sm"
      color="slate"
      variant="faded"
      :is-loading="isWorking"
      data-test="conversation-queue"
      @click="sendToQueue"
    />
    <Button
      :label="t('CHATCLEAN.QUEUE.TRANSFER')"
      icon="i-lucide-arrow-right-left"
      size="sm"
      color="slate"
      variant="faded"
      data-test="conversation-transfer"
      @click="transferDialogRef.open()"
    />
    <TransferDialog
      ref="transferDialogRef"
      :conversation-id="chat.id"
      :inbox-id="chat.inbox_id"
    />
  </div>
</template>
