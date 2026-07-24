<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import NextButton from 'next/button/Button.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const POLL_INTERVAL_MS = 3000;
const QR_REFRESH_SECONDS = 50;

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const pollTimer = ref(null);
const countdownTimer = ref(null);
const countdownSeconds = ref(0);
const diagnosis = ref(null);

const activeConnection = useMapGetter('optimiaWhatsappConnections/getActiveConnection');
const activeQr = useMapGetter('optimiaWhatsappConnections/getActiveQr');
const uiFlags = useMapGetter('optimiaWhatsappConnections/getUIFlags');

const connectionId = computed(() => Number(route.params.connectionId));
const isLoading = computed(() => uiFlags.value.isFetching || uiFlags.value.isUpdating);
const qrImage = computed(() => activeQr.value?.image_base64 || '');
const isReady = computed(() => activeConnection.value?.state === 'ready');
const showQr = computed(() => qrImage.value && !isReady.value && ['qr_required', 'waiting_scan', 'waiting_qr', 'reconnecting', 'pairing'].includes(activeConnection.value?.state));
const stateLabel = computed(() =>
  t(`OPTIMIA_CHANNEL_MANAGER.WHATSAPP.STATES.${activeConnection.value?.state}`, activeConnection.value?.state)
);
const healthLabel = computed(() =>
  t(
    `OPTIMIA_CHANNEL_MANAGER.WHATSAPP.HEALTH.${(activeConnection.value?.health_status || '').toUpperCase()}`,
    activeConnection.value?.health_status
  )
);

const formatDate = value => {
  if (!value) return '—';
  return new Date(value).toLocaleString();
};

const clearTimers = () => {
  if (pollTimer.value) {
    clearInterval(pollTimer.value);
    pollTimer.value = null;
  }
  if (countdownTimer.value) {
    clearInterval(countdownTimer.value);
    countdownTimer.value = null;
  }
};

const startCountdown = seconds => {
  countdownSeconds.value = seconds;
  clearInterval(countdownTimer.value);
  countdownTimer.value = setInterval(() => {
    if (countdownSeconds.value <= 0) {
      clearInterval(countdownTimer.value);
      countdownTimer.value = null;
      return;
    }
    countdownSeconds.value -= 1;
  }, 1000);
};

const pollStatus = async () => {
  try {
    const connection = await store.dispatch(
      'optimiaWhatsappConnections/refreshStatus',
      connectionId.value
    );
    if (connection.state === 'ready') {
      clearTimers();
    }
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

const startPolling = () => {
  clearTimers();
  pollTimer.value = setInterval(pollStatus, POLL_INTERVAL_MS);
};

const loadQrFlow = async () => {
  try {
    const data = await store.dispatch('optimiaWhatsappConnections/generateQr', connectionId.value);
    startCountdown(data.qr?.countdown_seconds || QR_REFRESH_SECONDS);
    startPolling();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

const refreshQr = async () => {
  await loadQrFlow();
};

const reconnect = async () => {
  if (!window.confirm(t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.CONFIRM_RECONNECT'))) return;

  try {
    clearTimers();
    await store.dispatch('optimiaWhatsappConnections/reconnect', connectionId.value);
    startPolling();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

const disconnect = async () => {
  if (!window.confirm(t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.CONFIRM_DISCONNECT'))) return;

  try {
    clearTimers();
    await store.dispatch('optimiaWhatsappConnections/disconnect', connectionId.value);
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

const syncWebhook = async () => {
  try {
    await store.dispatch('optimiaWhatsappConnections/syncWebhook', connectionId.value);
    useAlert(t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DETAILS.WEBHOOK'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

const runDiagnose = async () => {
  try {
    diagnosis.value = await store.dispatch('optimiaWhatsappConnections/diagnose', connectionId.value);
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};

onMounted(async () => {
  await store.dispatch('optimiaWhatsappConnections/fetchConnection', connectionId.value);
  if (isReady.value) return;

  const statesWithQr = ['draft', 'creating', 'created', 'waiting_qr', 'disconnected', 'error', 'failed', 'reconnecting', 'qr_required'];
  if (statesWithQr.includes(activeConnection.value?.state)) {
    await loadQrFlow();
    return;
  }

  startPolling();
});

onBeforeUnmount(() => {
  clearTimers();
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <LoadingState v-if="isLoading && !activeConnection" />

    <template v-else-if="activeConnection">
      <div class="rounded-2xl border border-n-weak p-6">
        <h1 class="text-lg font-medium text-n-slate-12">
          {{ activeConnection.display_name }}
        </h1>
        <p
          v-if="['error', 'failed'].includes(activeConnection.state) && activeConnection.status_message"
          class="mt-2 rounded-xl bg-n-ruby-9/10 px-4 py-3 text-sm text-n-ruby-11"
        >
          {{ activeConnection.status_message }}
        </p>
        <dl class="mt-4 grid gap-3 text-sm">
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.STATUS') }}</dt>
            <dd class="text-n-slate-12">{{ stateLabel }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.HEALTH') }}</dt>
            <dd class="text-n-slate-12">{{ healthLabel }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.PHONE') }}</dt>
            <dd class="text-n-slate-12">{{ activeConnection.masked_phone_number || '—' }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DETAILS.LAST_CONNECTED') }}</dt>
            <dd class="text-n-slate-12">{{ formatDate(activeConnection.last_connected_at) }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DETAILS.LAST_CHECK') }}</dt>
            <dd class="text-n-slate-12">{{ formatDate(activeConnection.last_health_check_at) }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DETAILS.LAST_STATE_CHANGE') }}</dt>
            <dd class="text-n-slate-12">{{ formatDate(activeConnection.last_state_change_at) }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.LIST.INBOX') }}</dt>
            <dd class="text-n-slate-12">{{ activeConnection.inbox_id || '—' }}</dd>
          </div>
          <div class="flex justify-between gap-4">
            <dt class="text-n-slate-11">{{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DETAILS.WEBHOOK') }}</dt>
            <dd class="text-n-slate-12">{{ activeConnection.webhook_configured ? 'OK' : '—' }}</dd>
          </div>
        </dl>

        <div class="mt-6 flex flex-wrap gap-3">
          <NextButton
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.VIEW')"
            @click="pollStatus"
          />
          <NextButton
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.RECONNECT')"
            @click="reconnect"
          />
          <NextButton
            faded
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.REFRESH_QR')"
            @click="refreshQr"
          />
          <NextButton
            faded
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.SYNC_WEBHOOK')"
            @click="syncWebhook"
          />
          <NextButton
            faded
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.DIAGNOSE')"
            @click="runDiagnose"
          />
          <NextButton
            ruby
            faded
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ACTIONS.DISCONNECT')"
            @click="disconnect"
          />
        </div>
      </div>

      <div v-if="diagnosis" class="rounded-2xl border border-n-weak p-6 text-sm text-n-slate-12">
        <pre class="overflow-auto whitespace-pre-wrap">{{ JSON.stringify(diagnosis, null, 2) }}</pre>
      </div>

      <div v-if="isReady" class="max-w-lg rounded-2xl border border-n-weak p-6">
        <h2 class="text-lg font-medium text-n-slate-12">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.SUCCESS_TITLE') }}
        </h2>
        <p class="mt-2 text-sm text-n-slate-11">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.SUCCESS_DESCRIPTION') }}
        </p>
      </div>

      <div v-else-if="showQr" class="max-w-lg rounded-2xl border border-n-weak p-6">
        <h2 class="text-lg font-medium text-n-slate-12">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.SCAN_TITLE') }}
        </h2>
        <p class="mt-2 text-sm text-n-slate-11">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.SCAN_DESCRIPTION') }}
        </p>

        <div class="mt-6 flex flex-col items-center gap-4">
          <img :src="qrImage" alt="QR" class="h-64 w-64 rounded-xl border border-n-weak bg-white p-3" />
          <p class="text-sm text-n-slate-11">
            {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.COUNTDOWN', { seconds: countdownSeconds }) }}
          </p>
          <NextButton
            faded
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.REFRESH_QR')"
            @click="refreshQr"
          />
        </div>
      </div>
    </template>
  </div>
</template>
