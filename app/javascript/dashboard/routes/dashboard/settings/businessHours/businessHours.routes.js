import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

// Horário de atendimento da conta e feriados (US 19, CCV2-27).
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/business-hours'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'chatclean_business_hours_index',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
