/* global axios */
import ApiClient from '../ApiClient';

class CrmPipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  summary(id, params = {}) {
    return axios.get(`${this.url}/${id}/summary`, { params });
  }

  createStage(pipelineId, stage) {
    return axios.post(`${this.url}/${pipelineId}/stages`, { stage });
  }

  updateStage(pipelineId, stageId, stage) {
    return axios.patch(`${this.url}/${pipelineId}/stages/${stageId}`, {
      stage,
    });
  }

  deleteStage(pipelineId, stageId) {
    return axios.delete(`${this.url}/${pipelineId}/stages/${stageId}`);
  }

  reorderStages(id, stageIds) {
    return axios.post(`${this.url}/${id}/stages/reorder`, {
      stage_ids: stageIds,
    });
  }
}

export default new CrmPipelinesAPI();
