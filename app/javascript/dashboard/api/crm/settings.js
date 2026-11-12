/* global axios */
import ApiClient from '../ApiClient';

class CrmSettingsAPI extends ApiClient {
  constructor() {
    super('crm/settings', { accountScoped: true });
  }

  update(crm) {
    return axios.patch(this.url, { crm });
  }
}

export default new CrmSettingsAPI();
