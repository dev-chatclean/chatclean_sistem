/* global axios */
import ApiClient from '../ApiClient';

class CrmImpulsesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  stageUrl(pipelineId, stageId) {
    return `${this.url}/${pipelineId}/stages/${stageId}/impulses`;
  }

  list(pipelineId, stageId) {
    return axios.get(this.stageUrl(pipelineId, stageId));
  }

  createImpulse(pipelineId, stageId, impulse) {
    return axios.post(this.stageUrl(pipelineId, stageId), { impulse });
  }

  updateImpulse(pipelineId, stageId, impulseId, impulse) {
    return axios.patch(`${this.stageUrl(pipelineId, stageId)}/${impulseId}`, {
      impulse,
    });
  }

  deleteImpulse(pipelineId, stageId, impulseId) {
    return axios.delete(`${this.stageUrl(pipelineId, stageId)}/${impulseId}`);
  }
}

export default new CrmImpulsesAPI();
