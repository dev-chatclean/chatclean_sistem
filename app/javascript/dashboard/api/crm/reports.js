/* global axios */
import ApiClient from '../ApiClient';

class CrmReportsAPI extends ApiClient {
  constructor() {
    super('crm/reports', { accountScoped: true });
  }

  sales(params, { signal } = {}) {
    return axios.get(`${this.url}/sales`, { params, signal });
  }
}

export default new CrmReportsAPI();
