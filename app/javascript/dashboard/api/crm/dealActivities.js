/* global axios */
import ApiClient from '../ApiClient';

class CrmDealActivitiesAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  activitiesUrl(dealId) {
    return `${this.url}/${dealId}/activities`;
  }

  createFor(dealId, activity) {
    return axios.post(this.activitiesUrl(dealId), { activity });
  }

  updateFor(dealId, id, activity) {
    return axios.patch(`${this.activitiesUrl(dealId)}/${id}`, { activity });
  }

  deleteFor(dealId, id) {
    return axios.delete(`${this.activitiesUrl(dealId)}/${id}`);
  }
}

export default new CrmDealActivitiesAPI();
