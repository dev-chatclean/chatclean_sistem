/* global axios */
import ApiClient from '../ApiClient';

class CrmDealsAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  list(pipelineId, view = 'open') {
    return axios.get(this.url, { params: { pipeline_id: pipelineId, view } });
  }

  forContact(contactId) {
    return axios.get(this.url, { params: { contact_id: contactId } });
  }

  duplicate(id) {
    return axios.post(`${this.url}/${id}/duplicate`);
  }
}

export default new CrmDealsAPI();
