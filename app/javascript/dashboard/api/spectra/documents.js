/* global axios */

import ApiClient from '../ApiClient';

class SpectraDocumentsAPI extends ApiClient {
  constructor() {
    super('spectra/documents', { accountScoped: true });
  }

  getSendable({ q = '', category = '', tag = '', limit = 100 } = {}) {
    return axios.get(this.url, {
      params: { q, category, tag, limit },
    });
  }

  createDownloadToken(itemId) {
    return axios.post(`${this.url}/${itemId}/download_token`);
  }

  downloadDocument(itemId, token) {
    return axios.get(`${this.url}/${itemId}/download`, {
      params: { token },
      responseType: 'blob',
    });
  }
}

export default new SpectraDocumentsAPI();
