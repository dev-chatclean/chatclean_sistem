/* global axios */
import ApiClient from '../ApiClient';

// Ações de atendimento da ChatClean (US 15): aceitar e transferir.
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
}

export default new ChatcleanConversationsAPI();
