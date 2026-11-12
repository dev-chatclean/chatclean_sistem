/* global axios */
import ApiClient from '../ApiClient';

class CrmDealFilesAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  upload(dealId, file, category) {
    const data = new FormData();
    data.append('file', file);
    data.append('category', category);
    return axios.post(`${this.url}/${dealId}/files`, data);
  }

  remove(dealId, id) {
    return axios.delete(`${this.url}/${dealId}/files/${id}`);
  }
}

export default new CrmDealFilesAPI();
