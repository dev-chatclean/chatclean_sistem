import { frontendURL } from '../../../helper/URLHelper';
import CrmKanban from './pages/CrmKanban.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm/kanban'),
    name: 'crm_kanban',
    component: CrmKanban,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
];
