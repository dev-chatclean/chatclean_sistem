import ApiClient from '../ApiClient';

class CrmPipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }
}

export default new CrmPipelinesAPI();
