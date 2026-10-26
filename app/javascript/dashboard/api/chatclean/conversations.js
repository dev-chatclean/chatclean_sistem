/* global axios */
import ApiClient from '../ApiClient';

// Ações de atendimento da ChatClean: aceitar e transferir (US 15) e fechar com motivo (US 16).
class ChatcleanConversationsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  accept(conversationId) {
    return axios.post(`${this.url}/${conversationId}/acceptance`);
  }

  transfer(conversationId, { teamId, assigneeId, note }) {
    return axios.post(`${this.url}/${conversationId}/transfer`, {
      team_id: teamId,
      assignee_id: assigneeId,
      note,
    });
  }

  close(conversationId, { closingReasonId, saleValue }) {
    return axios.post(`${this.url}/${conversationId}/toggle_status`, {
      status: 'resolved',
      closing_reason_id: closingReasonId,
      sale_value: saleValue,
    });
  }
}

export default new ChatcleanConversationsAPI();
