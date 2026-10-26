/* global axios */
import ApiClient from '../ApiClient';

// Horário de atendimento da conta (US 19).
class WorkingScheduleAPI extends ApiClient {
  constructor() {
    super('working_schedule', { accountScoped: true });
  }

  show() {
    return axios.get(this.url);
  }

  save(schedule) {
    return axios.put(this.url, { working_schedule: schedule });
  }
}

export default new WorkingScheduleAPI();
