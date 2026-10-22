import { mount } from '@vue/test-utils';
import CreateDealDialog from '../CreateDealDialog.vue';

const pipelines = [
  {
    id: 1,
    name: 'Vendas',
    stages: [
      { id: 10, status: 'open' },
      { id: 11, status: 'open' },
      { id: 12, status: 'won' },
    ],
  },
  {
    id: 2,
    name: 'Parcerias',
    stages: [
      { id: 20, status: 'open' },
      { id: 21, status: 'won' },
    ],
  },
];

const fieldStub = {
  props: ['modelValue'],
  emits: ['update:modelValue'],
  template:
    '<input :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
};

const mountDialog = () =>
  mount(CreateDealDialog, {
    props: {
      pipelines,
      defaultPipelineId: 2,
      agents: [{ id: 3, name: 'Ana' }],
      currentUserId: 3,
    },
    global: {
      stubs: {
        Dialog: {
          props: ['disableConfirmButton'],
          emits: ['confirm'],
          methods: { open: vi.fn(), close: vi.fn() },
          template:
            '<div><slot /><button data-test="confirm" :disabled="disableConfirmButton" @click="$emit(\'confirm\')" /></div>',
        },
        Input: fieldStub,
        Select: fieldStub,
      },
    },
  });

describe('CreateDealDialog', () => {
  it('abre no pipeline padrão, no primeiro estágio aberto e com o agente atual', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="deal-pipeline"]').element.value).toBe('2');
    expect(wrapper.find('[data-test="deal-stage"]').element.value).toBe('20');
    expect(wrapper.find('[data-test="deal-assignee"]').element.value).toBe('3');
  });

  it('exige o título antes de liberar a criação', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeDefined();
    await wrapper.find('[data-test="deal-title"]').setValue('Plano anual');
    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeUndefined();
  });

  it('ao trocar de pipeline, volta para o primeiro estágio aberto dele', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    // O Select real devolve o value da opção com o tipo original (número).
    wrapper
      .findAllComponents(fieldStub)
      .find(c => c.attributes('data-test') === 'deal-pipeline')
      .vm.$emit('update:modelValue', 1);
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="deal-stage"]').element.value).toBe('10');
  });

  it('emite os atributos do deal', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();
    await wrapper.find('[data-test="deal-title"]').setValue('  Plano anual ');
    await wrapper.find('[data-test="deal-value"]').setValue('1500.5');
    await wrapper.find('[data-test="confirm"]').trigger('click');

    expect(wrapper.emitted('create')).toEqual([
      [
        {
          title: 'Plano anual',
          value: 1500.5,
          crm_stage_id: 20,
          expected_close_date: null,
          assignee_id: 3,
        },
      ],
    ]);
  });
});
