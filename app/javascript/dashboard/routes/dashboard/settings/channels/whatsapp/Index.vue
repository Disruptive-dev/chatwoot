<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import NextButton from 'next/button/Button.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const connections = useMapGetter('optimiaWhatsappConnections/getConnections');
const uiFlags = useMapGetter('optimiaWhatsappConnections/getUIFlags');

const isLoading = computed(() => uiFlags.value.isFetching);
const hasConnections = computed(() => connections.value.length > 0);

const stateLabel = state =>
  t(`OPTIMIA_CHANNEL_MANAGER.WHATSAPP.STATES.${state}`, state);

const healthLabel = healthStatus => {
  const key = (healthStatus || '').toUpperCase();
  return t(`OPTIMIA_CHANNEL_MANAGER.WHATSAPP.HEALTH.${key}`, healthStatus || '—');
};

const formatDate = value => {
  if (!value) return '—';
  return new Date(value).toLocaleString();
};

const goToNew = () => {
  router.push({ name: 'settings_channels_whatsapp_new' });
};

const goToConnection = connection => {
  router.push({
    name: 'settings_channels_whatsapp_show',
    params: { connectionId: connection.id },
  });
};

onMounted(() => {
  store.dispatch('optimiaWhatsappConnections/fetchConnections');
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex items-start justify-between gap-4">
      <div>
        <h1 class="text-lg font-medium text-n-slate-12">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-n-slate-11">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DESCRIPTION') }}
        </p>
      </div>
      <NextButton :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.CONNECT_BUTTON')" @click="goToNew" />
    </div>

    <LoadingState v-if="isLoading" />

    <div
      v-else-if="!hasConnections"
      class="rounded-2xl border border-dashed border-n-weak p-10 text-center"
    >
      <p class="text-sm text-n-slate-11">
        {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.EMPTY') }}
      </p>
      <div class="mt-4">
        <NextButton
          :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.CONNECT_BUTTON')"
          @click="goToNew"
        />
      </div>
    </div>

    <div v-else class="overflow-hidden rounded-2xl border border-n-weak">
      <table class="min-w-full divide-y divide-n-weak">
        <thead class="bg-n-alpha-1">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.STATUS') }}
            </th>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.HEALTH') }}
            </th>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.PHONE') }}
            </th>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.LAST_CHECK') }}
            </th>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.RECONNECTS') }}
            </th>
            <th class="px-4 py-3 text-left text-xs font-medium uppercase text-n-slate-11">
              {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.INBOX') }}
            </th>
            <th class="px-4 py-3" />
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak bg-n-solid-1">
          <tr v-for="connection in connections" :key="connection.id">
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ connection.display_name }}
              <div class="text-xs text-n-slate-11">{{ stateLabel(connection.state) }}</div>
            </td>
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ healthLabel(connection.health_status) }}
            </td>
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ connection.masked_phone_number || '—' }}
            </td>
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ formatDate(connection.last_health_check_at) }}
            </td>
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ connection.recent_reconnect_count ?? 0 }}
            </td>
            <td class="px-4 py-4 text-sm text-n-slate-12">
              {{ connection.inbox_id || '—' }}
            </td>
            <td class="px-4 py-4 text-right">
              <NextButton
                faded
                sm
                :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.VIEW')"
                @click="goToConnection(connection)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
