import { setActivePinia, createPinia } from 'pinia';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmLossReasonsAPI from 'dashboard/api/crm/lossReasons';
import { useCrmSettingsStore } from '../crmSettings';

vi.mock('dashboard/api/crm/pipelines', () => ({
  default: {
    get: vi.fn(),
    show: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    createStage: vi.fn(),
    updateStage: vi.fn(),
    deleteStage: vi.fn(),
    reorderStages: vi.fn(),
  },
}));

vi.mock('dashboard/api/crm/lossReasons', () => ({
  default: { get: vi.fn(), create: vi.fn(), update: vi.fn() },
}));

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(error => {
    throw error;
  }),
}));

const response = payload => ({ data: { payload } });

const stages = [
  { id: 1, status: 'open' },
  { id: 2, status: 'open' },
  { id: 3, status: 'won' },
  { id: 4, status: 'lost' },
];

describe('crmSettings store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('recarrega a lista ao criar um funil, porque o padrão anterior pode ter mudado', async () => {
    CrmPipelinesAPI.create.mockResolvedValue(
      response({ id: 9, is_default: true })
    );
    CrmPipelinesAPI.get.mockResolvedValue(
      response([
        { id: 1, is_default: false },
        { id: 9, is_default: true },
      ])
    );
    const store = useCrmSettingsStore();

    const created = await store.createPipeline({
      name: 'Novo',
      is_default: true,
    });

    expect(CrmPipelinesAPI.create).toHaveBeenCalledWith({
      pipeline: { name: 'Novo', is_default: true },
    });
    expect(created.id).toBe(9);
    expect(store.defaultPipeline.id).toBe(9);
  });

  it('mantém o funil na lista quando a exclusão é recusada', async () => {
    const store = useCrmSettingsStore();
    store.pipelines = [{ id: 1 }];
    CrmPipelinesAPI.delete.mockRejectedValue(new Error('tem negócios'));

    await expect(store.deletePipeline(1)).rejects.toThrow('tem negócios');
    expect(store.pipelines).toEqual([{ id: 1 }]);
  });

  it('cria estágio e recarrega o funil com as posições do servidor', async () => {
    const store = useCrmSettingsStore();
    store.pipelines = [{ id: 1, stages: [] }];
    CrmPipelinesAPI.createStage.mockResolvedValue(response({}));
    CrmPipelinesAPI.show.mockResolvedValue(
      response({ id: 1, stages: [{ id: 5, status: 'open' }] })
    );

    await store.createStage(1, { name: 'Proposta', probability: 40 });

    expect(CrmPipelinesAPI.createStage).toHaveBeenCalledWith(1, {
      name: 'Proposta',
      probability: 40,
    });
    expect(store.pipelines[0].stages).toEqual([{ id: 5, status: 'open' }]);
  });

  it('reordena na hora e volta à ordem anterior se a API falhar', async () => {
    const store = useCrmSettingsStore();
    store.pipelines = [{ id: 1, stages: [...stages] }];
    CrmPipelinesAPI.reorderStages.mockRejectedValue(new Error('falhou'));

    const pending = store.reorderStages(1, [2, 1]);
    expect(store.pipelines[0].stages.map(stage => stage.id)).toEqual([
      2, 1, 3, 4,
    ]);
    await expect(pending).rejects.toThrow('falhou');

    expect(CrmPipelinesAPI.reorderStages).toHaveBeenCalledWith(1, [2, 1]);
    expect(store.pipelines[0].stages.map(stage => stage.id)).toEqual([
      1, 2, 3, 4,
    ]);
  });

  it('atualiza o motivo de perda com a resposta da API', async () => {
    const store = useCrmSettingsStore();
    store.lossReasons = [{ id: 1, isActive: true }];
    CrmLossReasonsAPI.update.mockResolvedValue(
      response({ id: 1, is_active: false, is_system: false })
    );

    await store.updateLossReason(1, { is_active: false });

    expect(CrmLossReasonsAPI.update).toHaveBeenCalledWith(1, {
      loss_reason: { is_active: false },
    });
    expect(store.lossReasons).toEqual([
      { id: 1, isActive: false, isSystem: false },
    ]);
  });
});
