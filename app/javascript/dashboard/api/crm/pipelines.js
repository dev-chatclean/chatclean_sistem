/* global axios */
import ApiClient from '../ApiClient';

class CrmPipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  summary(id, params = {}) {
    return axios.get(`${this.url}/${id}/summary`, { params });
  }

  reorderStages(id, stageIds) {
    return axios.post(`${this.url}/${id}/stages/reorder`, {
      stage_ids: stageIds,
    });
  }
}

export default new CrmPipelinesAPI();
