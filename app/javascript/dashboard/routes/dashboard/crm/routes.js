import { frontendURL } from '../../../helper/URLHelper';
import PipelinesBoard from './pages/PipelinesBoard.vue';

const meta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    name: 'crm_pipelines_index',
    component: PipelinesBoard,
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/pipelines/:pipelineId'),
    name: 'crm_pipelines_show',
    component: PipelinesBoard,
    meta,
  },
];
