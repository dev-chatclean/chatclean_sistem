import { frontendURL } from '../../../helper/URLHelper';
import SettingsWrapper from '../settings/SettingsWrapper.vue';
import ProductsSettings from './pages/ProductsSettings.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/products'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'crm_products_list',
          meta: { permissions: ['administrator'] },
          component: ProductsSettings,
        },
      ],
    },
  ],
};
