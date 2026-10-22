import { setActivePinia, createPinia } from 'pinia';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmLossReasonsAPI from 'dashboard/api/crm/lossReasons';
import { useCrmConversationStore } from '../crmConversation';

vi.mock('dashboard/api/crm/deals', () => ({
  default: { get: vi.fn(), create: vi.fn(), update: vi.fn() },
}));

vi.mock('dashboard/api/crm/pipelines', () => ({
  default: { get: vi.fn() },
}));

vi.mock('dashboard/api/crm/lossReasons', () => ({
  default: { getActive: vi.fn() },
}));

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(error => {
    throw error;
  }),
}));

const response = payload => ({ data: { payload } });

describe('crmConversation store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    CrmPipelinesAPI.get.mockResolvedValue(
      response([
        { id: 1, name: 'Vendas', is_default: false, stages: [] },
        { id: 2, name: 'Padrão', is_default: true, stages: [] },
      ])
    );
    CrmLossReasonsAPI.getActive.mockResolvedValue(
      response([{ id: 5, name: 'Preço' }])
    );
  });

  it('carrega os deals do contato, separando abertos e finalizados pelos mais recentes', async () => {
    CrmDealsAPI.get.mockResolvedValue(
      response([
        { id: 1, status: 'lost', updated_at: 30 },
        { id: 2, status: 'open', updated_at: 10 },
        { id: 3, status: 'open', updated_at: 20 },
        { id: 4, status: 'won', updated_at: 40 },
      ])
    );
    const store = useCrmConversationStore();

    await store.fetchPanel(7);

    expect(CrmDealsAPI.get).toHaveBeenCalledWith({ contact_id: 7 });
    expect(store.openDeals.map(deal => deal.id)).toEqual([3, 2]);
    expect(store.closedDeals.map(deal => deal.id)).toEqual([4, 1]);
    expect(store.defaultPipeline.id).toBe(2);
    expect(store.lossReasons).toEqual([{ id: 5, name: 'Preço' }]);
  });

  it('ignora a resposta de um contato que já não está aberto', async () => {
    let resolveFirst;
    CrmDealsAPI.get
      .mockReturnValueOnce(
        new Promise(resolve => {
          resolveFirst = resolve;
        })
      )
      .mockResolvedValueOnce(
        response([{ id: 9, status: 'open', updated_at: 1 }])
      );
    const store = useCrmConversationStore();

    const first = store.fetchPanel(1);
    await store.fetchPanel(2);
    resolveFirst(response([{ id: 1, status: 'open', updated_at: 1 }]));
    await first;

    expect(store.deals.map(deal => deal.id)).toEqual([9]);
  });

  it('cria o deal e coloca no topo da lista', async () => {
    const store = useCrmConversationStore();
    store.deals = [{ id: 1 }];
    CrmDealsAPI.create.mockResolvedValue(
      response({ id: 2, title: 'Novo', crm_stage_id: 3 })
    );

    await store.createDeal({ title: 'Novo', conversation_display_id: 12 });

    expect(CrmDealsAPI.create).toHaveBeenCalledWith({
      deal: { title: 'Novo', conversation_display_id: 12 },
    });
    expect(store.deals.map(deal => deal.id)).toEqual([2, 1]);
    expect(store.uiFlags.isCreating).toBe(false);
  });

  it('troca o deal pela versão da API e mantém o anterior quando ela recusa', async () => {
    const store = useCrmConversationStore();
    const deal = { id: 1, crmStageId: 3 };
    store.deals = [deal];
    CrmDealsAPI.update.mockResolvedValueOnce(
      response({ id: 1, crm_stage_id: 4 })
    );

    await store.updateDeal(deal, { crm_stage_id: 4 });
    expect(store.deals).toEqual([{ id: 1, crmStageId: 4 }]);

    CrmDealsAPI.update.mockRejectedValueOnce(new Error('bloqueado'));
    await expect(
      store.updateDeal(store.deals[0], { crm_stage_id: 5 })
    ).rejects.toThrow('bloqueado');
    expect(store.deals).toEqual([{ id: 1, crmStageId: 4 }]);
  });
});
