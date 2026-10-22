import { mount, flushPromises } from '@vue/test-utils';
import { setActivePinia, createPinia } from 'pinia';
import { useAlert } from 'dashboard/composables';
import { useCrmSettingsStore } from 'dashboard/stores/crmSettings';
import PipelinesTab from '../PipelinesTab.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const pipelines = [
  {
    id: 1,
    name: 'Vendas',
    isDefault: true,
    stages: [
      { id: 10, name: 'Novo', status: 'open', probability: 10 },
      { id: 11, name: 'Proposta', status: 'open', probability: 50 },
      { id: 12, name: 'Ganho', status: 'won', probability: 100 },
      { id: 13, name: 'Perdido', status: 'lost', probability: 0 },
    ],
  },
  { id: 2, name: 'Parcerias', isDefault: false, stages: [] },
];

let crm;

const mountTab = () =>
  mount(PipelinesTab, {
    global: {
      stubs: {
        Draggable: {
          props: ['modelValue'],
          emits: ['update:modelValue'],
          template:
            '<div data-test="draggable"><slot v-for="element in modelValue" :key="element.id" name="item" :element="element" /></div>',
        },
        Button: {
          props: ['label', 'title'],
          emits: ['click'],
          template:
            '<button :title="title" @click="$emit(\'click\')">{{ label }}</button>',
        },
        Icon: true,
        Spinner: true,
        PipelineDialog: {
          methods: { open: vi.fn(), close: vi.fn() },
          template: '<div />',
        },
        StageDialog: {
          methods: { open: vi.fn(), close: vi.fn() },
          template: '<div />',
        },
        Dialog: {
          props: ['title'],
          emits: ['confirm'],
          methods: { open: vi.fn(), close: vi.fn() },
          template:
            '<button data-test="confirm-delete" @click="$emit(\'confirm\')">{{ title }}</button>',
        },
      },
    },
  });

describe('PipelinesTab', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    crm = useCrmSettingsStore();
    crm.fetchPipelines = vi.fn().mockResolvedValue();
    crm.reorderStages = vi.fn().mockResolvedValue();
    crm.deletePipeline = vi.fn();
    crm.pipelines = structuredClone(pipelines);
  });

  it('lista os funis, marca o padrão e abre nele', async () => {
    const wrapper = mountTab();
    await flushPromises();

    expect(wrapper.findAll('[data-test="pipeline-item"]')).toHaveLength(2);
    expect(wrapper.findAll('[data-test="default-tag"]')).toHaveLength(1);
    expect(wrapper.findAll('[data-test="open-stage"]')).toHaveLength(2);
  });

  it('mostra Ganho e Perdido como encerramento, sem exclusão', () => {
    const wrapper = mountTab();
    const closing = wrapper.findAll('[data-test="closing-stage"]');

    expect(closing).toHaveLength(2);
    expect(closing[0].find('[data-test="delete-stage"]').exists()).toBe(false);
    expect(wrapper.findAll('[data-test="delete-stage"]')).toHaveLength(2);
  });

  it('reordena com os IDs de todos os estágios abertos', async () => {
    const wrapper = mountTab();
    const [first, second] = crm.pipelines[0].stages;

    wrapper
      .findComponent('[data-test="draggable"]')
      .vm.$emit('update:modelValue', [second, first]);
    await flushPromises();

    expect(crm.reorderStages).toHaveBeenCalledWith(1, [11, 10]);
  });

  it('mostra o erro da API quando a exclusão do funil é recusada', async () => {
    crm.deletePipeline.mockRejectedValue(new Error('O funil tem negócios'));
    const wrapper = mountTab();

    await wrapper.find('[data-test="delete-pipeline"]').trigger('click');
    await wrapper.find('[data-test="confirm-delete"]').trigger('click');
    await flushPromises();

    expect(crm.deletePipeline).toHaveBeenCalledWith(1);
    expect(useAlert).toHaveBeenCalledWith('O funil tem negócios');
    expect(wrapper.findAll('[data-test="pipeline-item"]')).toHaveLength(2);
  });
});
