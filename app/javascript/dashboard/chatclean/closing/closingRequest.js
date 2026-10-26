import { reactive } from 'vue';
import ChatcleanConversationsAPI from 'dashboard/api/chatclean/conversations';
import types from 'dashboard/store/mutation-types';

// Pedido de motivo de fechamento (US 16). Uma única janela, montada no Dashboard, atende todos os
// pontos que fecham atendimento. Quem pede passa `submit`, que fecha de fato com o motivo escolhido;
// a promessa termina em true quando fechou e em false quando a pessoa desistiu.
export const closingRequest = reactive({
  isOpen: false,
  count: 1,
  submit: null,
  finish: null,
});

export const askClosingReason = ({ count = 1, submit }) =>
  new Promise(finish => {
    Object.assign(closingRequest, { isOpen: true, count, submit, finish });
  });

export const closeConversation = (store, conversationId) =>
  askClosingReason({
    submit: async closing => {
      const { data } = await ChatcleanConversationsAPI.close(
        conversationId,
        closing
      );
      store.commit(types.CHANGE_CONVERSATION_STATUS, {
        conversationId,
        status: data.payload.current_status,
        snoozedUntil: null,
      });
    },
  });
