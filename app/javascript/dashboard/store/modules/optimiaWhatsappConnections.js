import OptimiaWhatsappConnectionsAPI from '../../api/optimia/whatsappConnections';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
  activeConnection: null,
  activeQr: null,
};

export const getters = {
  getConnections: $state => $state.records,
  getActiveConnection: $state => $state.activeConnection,
  getActiveQr: $state => $state.activeQr,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  fetchConnections: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const { data } = await OptimiaWhatsappConnectionsAPI.getConnections();
      commit('SET_RECORDS', data.data || []);
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  createConnection: async ({ commit }, payload) => {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const { data } = await OptimiaWhatsappConnectionsAPI.createConnection(payload);
      commit('UPSERT_RECORD', data.data);
      commit('SET_ACTIVE_CONNECTION', data.data);
      commit('SET_ACTIVE_QR', data.data.qr || null);
      return data.data;
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },

  fetchConnection: async ({ commit }, id) => {
    const { data } = await OptimiaWhatsappConnectionsAPI.getConnection(id);
    commit('UPSERT_RECORD', data.data);
    commit('SET_ACTIVE_CONNECTION', data.data);
    return data.data;
  },

  refreshStatus: async ({ commit }, id) => {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const { data } = await OptimiaWhatsappConnectionsAPI.getStatus(id);
      commit('UPSERT_RECORD', data.data);
      commit('SET_ACTIVE_CONNECTION', data.data);
      return data.data;
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },

  generateQr: async ({ commit }, id) => {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const { data } = await OptimiaWhatsappConnectionsAPI.generateQr(id);
      commit('UPSERT_RECORD', data.data);
      commit('SET_ACTIVE_CONNECTION', data.data);
      commit('SET_ACTIVE_QR', data.data.qr || null);
      return data.data;
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },

  reconnect: async ({ dispatch }, id) => {
    await OptimiaWhatsappConnectionsAPI.reconnect(id);
    return dispatch('generateQr', id);
  },

  disconnect: async ({ commit }, id) => {
    const { data } = await OptimiaWhatsappConnectionsAPI.disconnect(id);
    commit('UPSERT_RECORD', data.data);
    commit('SET_ACTIVE_CONNECTION', data.data);
    commit('SET_ACTIVE_QR', null);
    return data.data;
  },
};

export const mutations = {
  SET_UI_FLAG($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  SET_RECORDS($state, records) {
    $state.records = records;
  },
  UPSERT_RECORD($state, record) {
    const index = $state.records.findIndex(item => item.id === record.id);
    if (index === -1) {
      $state.records = [record, ...$state.records];
    } else {
      $state.records.splice(index, 1, record);
    }
  },
  SET_ACTIVE_CONNECTION($state, record) {
    $state.activeConnection = record;
  },
  SET_ACTIVE_QR($state, qr) {
    $state.activeQr = qr;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
