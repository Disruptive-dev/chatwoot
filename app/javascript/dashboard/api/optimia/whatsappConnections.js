/* global axios */

import ApiClient from '../ApiClient';

class OptimiaWhatsappConnectionsAPI extends ApiClient {
  constructor() {
    super('optimia/whatsapp/connections', { accountScoped: true });
  }

  getConnections() {
    return axios.get(this.url);
  }

  createConnection(payload) {
    return axios.post(this.url, payload);
  }

  getConnection(id) {
    return axios.get(`${this.url}/${id}`);
  }

  getStatus(id) {
    return axios.get(`${this.url}/${id}/status`);
  }

  generateQr(id) {
    return axios.post(`${this.url}/${id}/qr`);
  }

  reconnect(id) {
    return axios.post(`${this.url}/${id}/reconnect`);
  }

  disconnect(id) {
    return axios.post(`${this.url}/${id}/disconnect`);
  }

  requestPairingCode(id, phoneNumber) {
    return axios.post(`${this.url}/${id}/pairing_code`, {
      phone_number: phoneNumber,
    });
  }
}

export default new OptimiaWhatsappConnectionsAPI();
