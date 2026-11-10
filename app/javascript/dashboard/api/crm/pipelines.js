/* global axios */
import ApiClient from '../ApiClient';

class CrmPipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  updateStage(pipelineId, stageId, stage) {
    return axios.patch(`${this.url}/${pipelineId}/stages/${stageId}`, {
      stage,
    });
  }

  reorderStages(pipelineId, stageIds) {
    return axios.patch(`${this.url}/${pipelineId}/stages/reorder`, {
      stage_ids: stageIds,
    });
  }
}

export default new CrmPipelinesAPI();
