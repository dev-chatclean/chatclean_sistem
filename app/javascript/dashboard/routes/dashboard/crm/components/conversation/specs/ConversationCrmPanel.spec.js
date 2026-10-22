import { mount, flushPromises } from '@vue/test-utils';
import { setActivePinia, createPinia } from 'pinia';
import { ref } from 'vue';
import { useCrmConversationStore } from 'dashboard/stores/crmConversation';
import ConversationCrmPanel from '../ConversationCrmPanel.vue';

const isAdmin = ref(false);

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: getter =>
    ref(getter === 'getCurrentUserID' ? 3 : [{ id: 3, name: 'Ana' }]),
}));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const pipeline = {
  id: 1,
  name: 'Vendas',
  isDefault: true,
  stages: [
    { id: 10, name: 'Novo', status: 'open' },
    { id: 12, name: 'Perdido', status: 'lost' },
  ],
};

let crm;

const mountPanel = (props = {}) =>
  mount(ConversationCrmPanel, {
    props: { contactId: 5, conversationDisplayId: 42, ...props },
    global: {
      stubs: {
        RouterLink: { template: '<a><slot /></a>' },
        Button: {
          props: ['disabled', 'label'],
          template: '<button :disabled="disabled">{{ label }}</button>',
        },
        Icon: true,
        Spinner: true,
        ConversationDealCard: {
          props: ['deal', 'isCurrentConversation', 'locked'],
          emits: ['changeStage', 'assign'],
          template:
            '<div data-test="deal-card" :data-current="isCurrentConversation" :data-locked="locked">{{ deal.title }}</div>',
        },
        CreateDealDialog: {
          methods: { open: vi.fn(), close: vi.fn() },
          template: '<div />',
        },
        LossReasonModal: {
          methods: { open: vi.fn(), close: vi.fn() },
          template: '<div />',
        },
      },
    },
  });

describe('ConversationCrmPanel', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    crm = useCrmConversationStore();
    crm.fetchPanel = vi.fn();
    crm.fetchDeals = vi.fn();
    crm.updateDeal = vi.fn();
    crm.pipelines = [pipeline];
    isAdmin.value = false;
  });

  it('carrega os deals do contato e marca os da conversa aberta', async () => {
    crm.deals = [
      {
        id: 1,
        title: 'Desta conversa',
        status: 'open',
        updatedAt: 2,
        conversationDisplayId: 42,
        crmPipelineId: 1,
      },
      {
        id: 2,
        title: 'De outra',
        status: 'open',
        updatedAt: 1,
        conversationDisplayId: 7,
        crmPipelineId: 1,
      },
    ];
    const wrapper = mountPanel();
    await flushPromises();

    expect(crm.fetchPanel).toHaveBeenCalledWith(5);
    const cards = wrapper.findAll('[data-test="deal-card"]');
    expect(cards.map(card => card.attributes('data-current'))).toEqual([
      'true',
      'false',
    ]);
  });

  it('recolhe os finalizados atrás de "Ver finalizados"', async () => {
    crm.deals = [
      {
        id: 1,
        title: 'Aberto',
        status: 'open',
        updatedAt: 1,
        crmPipelineId: 1,
      },
      { id: 2, title: 'Ganho', status: 'won', updatedAt: 1, crmPipelineId: 1 },
    ];
    const wrapper = mountPanel();

    expect(wrapper.findAll('[data-test="deal-card"]')).toHaveLength(1);
    await wrapper.find('[data-test="toggle-closed"]').trigger('click');
    expect(wrapper.findAll('[data-test="deal-card"]')).toHaveLength(2);
  });

  it('mostra o aviso de bloqueio, trava os cards e desativa a criação', () => {
    crm.deals = [
      {
        id: 1,
        title: 'Perdido',
        status: 'open',
        updatedAt: 1,
        crmPipelineId: 1,
      },
    ];
    const wrapper = mountPanel({ contactBlocked: true });

    expect(wrapper.find('[data-test="blocked-alert"]').exists()).toBe(true);
    expect(
      wrapper.find('[data-test="deal-card"]').attributes('data-locked')
    ).toBe('true');
    expect(
      wrapper.find('[data-test="new-deal"]').attributes('disabled')
    ).toBeDefined();
  });

  it('sem funil, orienta o administrador e desativa a criação', () => {
    crm.pipelines = [];
    isAdmin.value = true;
    const wrapper = mountPanel();

    expect(wrapper.find('[data-test="no-pipeline"]').text()).toContain(
      'CRM.CONVERSATION_PANEL.NO_PIPELINE.ADMIN'
    );
    expect(wrapper.find('[data-test="settings-link"]').exists()).toBe(true);
    expect(
      wrapper.find('[data-test="new-deal"]').attributes('disabled')
    ).toBeDefined();
  });

  it('mostra o estado vazio quando o contato não tem deals', () => {
    crm.deals = [];
    expect(mountPanel().find('[data-test="no-deals"]').exists()).toBe(true);
  });

  it('só manda para Perdido depois do motivo; outros estágios vão direto', async () => {
    const deal = {
      id: 1,
      title: 'Plano',
      status: 'open',
      updatedAt: 1,
      crmStageId: 10,
      crmPipelineId: 1,
    };
    crm.deals = [deal];
    const wrapper = mountPanel();
    const card = wrapper.findComponent('[data-test="deal-card"]');

    card.vm.$emit('changeStage', 12);
    expect(crm.updateDeal).not.toHaveBeenCalled();

    card.vm.$emit('assign', 3);
    expect(crm.updateDeal).toHaveBeenCalledWith(deal, { assignee_id: 3 });
  });
});
