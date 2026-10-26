import { computed, reactive, watch } from 'vue';
import { debounce } from '@chatwoot/utils';
import { useEmitter } from 'dashboard/composables/emitter';
import ConversationApi from 'dashboard/api/inbox/conversation';
import wootConstants from 'dashboard/constants/globals';

// Contadores das abas da lista (US 15). Os números do Chatwoot valem para o status em uso, então,
// com a aba Fechados aberta, Ativos e Pendentes precisam dos abertos buscados à parte, e Fechados
// sempre conta os fechados. Seguem o mesmo canal, departamento e etiqueta da lista.
export function useChatTabCounts(filters) {
  const counts = reactive({
    mineCount: 0,
    unAssignedCount: 0,
    closedCount: 0,
  });

  const scope = computed(() => {
    const { inboxId, labels, teamId, conversationType } = filters.value;
    return { inboxId, labels, teamId, conversationType };
  });

  const fetchCounts = async () => {
    try {
      const [open, closed] = await Promise.all(
        [
          wootConstants.STATUS_TYPE.OPEN,
          wootConstants.STATUS_TYPE.RESOLVED,
        ].map(status => ConversationApi.meta({ ...scope.value, status }))
      );
      Object.assign(counts, {
        mineCount: open.data.meta.mine_count,
        unAssignedCount: open.data.meta.unassigned_count,
        closedCount: closed.data.meta.all_count,
      });
    } catch {
      // Mantém os últimos números; a próxima atualização tenta de novo.
    }
  };

  // As mudanças de atendimento chegam em rajadas pelo websocket.
  const debouncedFetchCounts = debounce(fetchCounts, 1000, false, 5000);

  watch(scope, fetchCounts, { immediate: true, deep: true });
  useEmitter('fetch_conversation_stats', debouncedFetchCounts);

  return counts;
}
