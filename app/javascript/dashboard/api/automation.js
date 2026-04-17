/* global axios */
import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  clone(automationId) {
    return axios.post(`${this.url}/${automationId}/clone`);
  }

  getLogs(automationId) {
    return axios.get(`${this.url}/${automationId}/logs`);
  }
}

export default new AutomationsAPI();
