/* global axios */
import ApiClient from '../ApiClient';

// Motivos de fechamento de atendimento (US 16).
class ClosingReasonsAPI extends ApiClient {
  constructor() {
    super('closing_reasons', { accountScoped: true });
  }

  // Só os ativos que a pessoa pode escolher ao fechar.
  getActive() {
    return axios.get(this.url, { params: { active: true } });
  }
}

export default new ClosingReasonsAPI();
