import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import SettingsContent from '../Wrapper.vue';
import WhatsappConnectionsIndex from './whatsapp/Index.vue';
import WhatsappConnectionNew from './whatsapp/New.vue';
import WhatsappConnectionShow from './whatsapp/Show.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/channels'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => ({
            name: 'settings_channels_whatsapp',
            params: to.params,
          }),
        },
        {
          path: 'whatsapp',
          name: 'settings_channels_whatsapp',
          component: WhatsappConnectionsIndex,
          meta: {
            featureFlag: FEATURE_FLAGS.OPTIMIA_CHANNEL_MANAGER,
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/channels/whatsapp'),
      component: SettingsContent,
      props: params => ({
        headerTitle: 'OPTIMIA_CHANNEL_MANAGER.WHATSAPP.TITLE',
        icon: 'i-woot-whatsapp',
        showBackButton: true,
        backUrl: { name: 'settings_channels_whatsapp' },
        fullWidth: params.name === 'settings_channels_whatsapp_new',
      }),
      children: [
        {
          path: 'new',
          name: 'settings_channels_whatsapp_new',
          component: WhatsappConnectionNew,
          meta: {
            featureFlag: FEATURE_FLAGS.OPTIMIA_CHANNEL_MANAGER,
            permissions: ['administrator'],
          },
        },
        {
          path: ':connectionId',
          name: 'settings_channels_whatsapp_show',
          component: WhatsappConnectionShow,
          meta: {
            featureFlag: FEATURE_FLAGS.OPTIMIA_CHANNEL_MANAGER,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
