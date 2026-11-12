/* global axios */
import ApiClient from './ApiClient';

class ContactArchivesAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  archive(contactId) {
    return axios.post(`${this.url}/${contactId}/archive`);
  }

  unarchive(contactId) {
    return axios.delete(`${this.url}/${contactId}/archive`);
  }
}

export default new ContactArchivesAPI();
