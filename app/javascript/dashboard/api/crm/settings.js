/* global axios */
import ApiClient from '../ApiClient';

class CrmSettingsAPI extends ApiClient {
  constructor() {
    super('crm/settings', { accountScoped: true });
  }

  update(data) {
    return axios.patch(this.url, data);
  }
}

export default new CrmSettingsAPI();
