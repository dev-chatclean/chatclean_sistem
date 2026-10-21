/* global axios */
import ApiClient from '../ApiClient';

class CrmLossReasonsAPI extends ApiClient {
  constructor() {
    super('crm/loss_reasons', { accountScoped: true });
  }

  getActive() {
    return axios.get(this.url, { params: { active: true } });
  }
}

export default new CrmLossReasonsAPI();
