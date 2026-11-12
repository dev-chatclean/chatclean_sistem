/* global axios */
import ApiClient from '../ApiClient';

class CrmStageCampaignsAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  stageUrl(pipelineId, stageId) {
    return `${this.url}/${pipelineId}/stages/${stageId}/campaigns`;
  }

  list(pipelineId, stageId) {
    return axios.get(this.stageUrl(pipelineId, stageId));
  }

  preview(pipelineId, stageId, filters, { signal } = {}) {
    return axios.post(
      `${this.stageUrl(pipelineId, stageId)}/preview`,
      { filters },
      { signal }
    );
  }

  createCampaign(pipelineId, stageId, campaign) {
    return axios.post(this.stageUrl(pipelineId, stageId), { campaign });
  }

  cancelPending(pipelineId, stageId, campaignId) {
    return axios.post(
      `${this.stageUrl(pipelineId, stageId)}/${campaignId}/cancel`
    );
  }
}

export default new CrmStageCampaignsAPI();
