/* global axios */
import ApiClient from '../ApiClient';

class CrmPipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  createStage(pipelineId, stage, afterStageId) {
    return axios.post(`${this.url}/${pipelineId}/stages`, {
      stage,
      after_stage_id: afterStageId,
    });
  }

  deleteStage(pipelineId, stageId, transferToStageId = null) {
    return axios.delete(`${this.url}/${pipelineId}/stages/${stageId}`, {
      data: { transfer_to_stage_id: transferToStageId },
    });
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
