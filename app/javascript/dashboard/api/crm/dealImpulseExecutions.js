/* global axios */
import ApiClient from '../ApiClient';

class CrmDealImpulseExecutionsAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  cancel(dealId, id) {
    return axios.delete(`${this.url}/${dealId}/impulse_executions/${id}`);
  }
}

export default new CrmDealImpulseExecutionsAPI();
