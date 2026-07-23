<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import NextButton from 'next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const displayName = ref('');
const uiFlags = useMapGetter('optimiaWhatsappConnections/getUIFlags');

const startConnection = async () => {
  if (!displayName.value.trim()) return;

  try {
    const connection = await store.dispatch('optimiaWhatsappConnections/createConnection', {
      display_name: displayName.value.trim(),
    });
    await router.push({
      name: 'settings_channels_whatsapp_show',
      params: { connectionId: connection.id },
    });
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.ERRORS.GENERIC'));
  }
};
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div>
      <h1 class="text-lg font-medium text-n-slate-12">
        {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.TITLE') }}
      </h1>
      <p class="mt-1 text-sm text-n-slate-11">
        {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.DESCRIPTION') }}
      </p>

      <div class="mt-6 max-w-lg rounded-2xl border border-n-weak p-6">
        <label class="mb-2 block text-sm font-medium text-n-slate-12">
          {{ $t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.DISPLAY_NAME_LABEL') }}
        </label>
        <input
          v-model="displayName"
          type="text"
          class="w-full rounded-xl border border-n-weak bg-n-solid-1 px-4 py-2 text-sm text-n-slate-12"
          :placeholder="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.DISPLAY_NAME_PLACEHOLDER')"
        />
        <div class="mt-4">
          <NextButton
            :label="$t('OPTIMIA_CHANNEL_MANAGER.WHATSAPP.WIZARD.START_BUTTON')"
            :is-loading="uiFlags.isCreating"
            @click="startConnection"
          />
        </div>
      </div>
    </div>
  </div>
</template>
