import { setActivePinia, createPinia } from 'pinia';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import { useCrmKanbanStore, DEALS_PER_PAGE } from '../crmKanban';

vi.mock('dashboard/api/crm/deals', () => ({
  default: { get: vi.fn(), update: vi.fn() },
}));

vi.mock('dashboard/api/crm/pipelines', () => ({
  default: { get: vi.fn(), summary: vi.fn(), reorderStages: vi.fn() },
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

const stages = [
  { id: 1, name: 'Novo', status: 'open', position: 1 },
  { id: 2, name: 'Proposta', status: 'open', position: 2 },
  { id: 3, name: 'Ganho', status: 'won', position: 1000 },
  { id: 4, name: 'Perdido', status: 'lost', position: 1001 },
];

const pipelines = [
  { id: 10, name: 'Vendas', is_default: false, stages: [] },
  { id: 11, name: 'Padrão', is_default: true, stages },
];

const buildStore = () => {
  const store = useCrmKanbanStore();
  store.pipelines = [
    {
      id: 11,
      name: 'Padrão',
      isDefault: true,
      stages: structuredClone(stages),
    },
  ];
  store.selectedPipelineId = 11;
  return store;
};

describe('crmKanban store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    CrmPipelinesAPI.summary.mockResolvedValue(response([]));
  });

  it('abre no pipeline padrão e separa estágios abertos dos de fechamento', async () => {
    CrmPipelinesAPI.get.mockResolvedValue(response(pipelines));
    const store = useCrmKanbanStore();

    await store.fetchPipelines();

    expect(store.selectedPipelineId).toBe(11);
    expect(store.openStages.map(stage => stage.id)).toEqual([1, 2]);
    expect(store.closingStages.map(stage => stage.id)).toEqual([3, 4]);
  });

  it('sem pipeline padrão, abre no primeiro', async () => {
    CrmPipelinesAPI.get.mockResolvedValue(response([pipelines[0]]));
    const store = useCrmKanbanStore();

    await store.fetchPipelines();

    expect(store.selectedPipelineId).toBe(10);
  });

  it('carrega cada coluna com o filtro de responsável e pagina sem duplicar', async () => {
    const store = buildStore();
    store.assigneeFilter = 'none';
    const fullPage = Array.from({ length: DEALS_PER_PAGE }, (_, index) => ({
      id: index + 1,
      crm_stage_id: 1,
    }));
    CrmDealsAPI.get.mockImplementation(({ crm_stage_id: stageId, page }) =>
      Promise.resolve(
        response(
          stageId === 1 && page === 1 ? fullPage : [{ id: 1, crm_stage_id: 1 }]
        )
      )
    );

    await store.loadBoard();
    expect(CrmDealsAPI.get).toHaveBeenCalledWith({
      crm_stage_id: 1,
      page: 1,
      assignee_id: 'none',
    });
    expect(CrmPipelinesAPI.summary).toHaveBeenCalledWith(11, {
      assignee_id: 'none',
    });
    expect(store.columns[1].hasMore).toBe(true);
    expect(store.columns[2].hasMore).toBe(false);

    await store.fetchColumn(1);
    expect(store.columns[1].deals).toHaveLength(DEALS_PER_PAGE);
    expect(store.columns[1].page).toBe(2);
  });

  it('guarda o resumo por estágio com o total numérico', async () => {
    const store = buildStore();
    CrmPipelinesAPI.summary.mockResolvedValue(
      response([{ crm_stage_id: 1, deals_count: 2, total_value: '150.5' }])
    );

    await store.fetchSummary();

    expect(store.summary).toEqual({ 1: { dealsCount: 2, totalValue: 150.5 } });
  });

  it('envia o motivo de perda e troca o card pela versão da API', async () => {
    const store = buildStore();
    const deal = { id: 9, title: 'Deal', crmStageId: 1 };
    store.columns = { 1: { deals: [] }, 4: { deals: [deal] } };
    CrmDealsAPI.update.mockResolvedValue(
      response({ id: 9, title: 'Deal', crm_stage_id: 4, status: 'lost' })
    );

    await store.moveDeal({
      deal,
      toStageId: 4,
      origin: { stageId: 1, index: 0 },
      lossReasonId: 5,
      lossDetails: '',
    });

    expect(CrmDealsAPI.update).toHaveBeenCalledWith(9, {
      deal: { crm_stage_id: 4, crm_loss_reason_id: 5, loss_details: null },
    });
    expect(store.columns[4].deals).toEqual([
      { id: 9, title: 'Deal', crmStageId: 4, status: 'lost' },
    ]);
    expect(CrmPipelinesAPI.summary).toHaveBeenCalled();
  });

  it('devolve o card à posição de origem quando a API recusa a mudança', async () => {
    const store = buildStore();
    const deal = { id: 9, crmStageId: 1 };
    const other = { id: 8, crmStageId: 1 };
    store.columns = { 1: { deals: [other] }, 2: { deals: [deal] } };
    CrmDealsAPI.update.mockRejectedValue(new Error('recusado'));

    await expect(
      store.moveDeal({ deal, toStageId: 2, origin: { stageId: 1, index: 0 } })
    ).rejects.toThrow('recusado');

    expect(store.columns[2].deals).toEqual([]);
    expect(store.columns[1].deals.map(item => item.id)).toEqual([9, 8]);
  });

  it('reordena os estágios abertos mantendo Ganho e Perdido no fim e desfaz se falhar', async () => {
    const store = buildStore();
    CrmPipelinesAPI.reorderStages.mockRejectedValue(new Error('sem permissão'));

    const pending = store.reorderStages([2, 1]);
    expect(store.stages.map(stage => stage.id)).toEqual([2, 1, 3, 4]);
    await expect(pending).rejects.toThrow('sem permissão');

    expect(CrmPipelinesAPI.reorderStages).toHaveBeenCalledWith(11, [2, 1]);
    expect(store.stages.map(stage => stage.id)).toEqual([1, 2, 3, 4]);
  });
});
