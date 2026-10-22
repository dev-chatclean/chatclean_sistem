import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

// Configurações do CRM do ChatClean: funis, estágios e motivos de perda (CCV2-17).
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/crm'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'crm_settings_index',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
