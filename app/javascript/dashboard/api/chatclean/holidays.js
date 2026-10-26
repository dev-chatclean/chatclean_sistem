/* global axios */
import ApiClient from '../ApiClient';

// Feriados da conta (US 19).
class HolidaysAPI extends ApiClient {
  constructor() {
    super('holidays', { accountScoped: true });
  }

  getByYear(year) {
    return axios.get(this.url, { params: { year } });
  }

  importNational(year) {
    return axios.post(`${this.url}/import_national`, { year });
  }
}

export default new HolidaysAPI();
