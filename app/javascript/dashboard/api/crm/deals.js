/* global axios */
import ApiClient from '../ApiClient';

class CrmDealsAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new CrmDealsAPI();
