import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

// Motivos de fechamento de atendimento (US 16, CCV2-24).
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/closing-reasons'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'closing_reasons_settings_index',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
