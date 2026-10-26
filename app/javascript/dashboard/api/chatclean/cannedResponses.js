/* global axios */
import ApiClient from '../ApiClient';

// Mensagens rápidas (US 17): a lista do administrador com as "Só eu" de todos os usuários.
class ChatcleanCannedResponsesAPI extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  getWithUserResponses() {
    return axios.get(this.url, { params: { include_personal: true } });
  }
}

export default new ChatcleanCannedResponsesAPI();
