import { mount } from '@vue/test-utils';
import PipelineDialog from '../PipelineDialog.vue';

const fieldStub = {
  props: ['modelValue'],
  emits: ['update:modelValue'],
  template:
    '<input :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
};

const mountDialog = defaultPipeline =>
  mount(PipelineDialog, {
    props: { defaultPipeline },
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
        TextArea: fieldStub,
        Switch: {
          props: ['modelValue'],
          emits: ['update:modelValue'],
          template:
            '<button data-test="switch" @click="$emit(\'update:modelValue\', !modelValue)" />',
        },
      },
    },
  });

describe('PipelineDialog', () => {
  it('avisa qual funil deixa de ser o padrão ao ligar o switch', async () => {
    const wrapper = mountDialog({ id: 1, name: 'Vendas' });
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="default-warning"]').exists()).toBe(false);
    await wrapper.find('[data-test="pipeline-default"]').trigger('click');

    expect(wrapper.find('[data-test="default-warning"]').exists()).toBe(true);
  });

  it('não avisa ao editar o próprio funil padrão', async () => {
    const pipeline = { id: 1, name: 'Vendas', isDefault: true };
    const wrapper = mountDialog(pipeline);
    wrapper.vm.open(pipeline);
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="default-warning"]').exists()).toBe(false);
  });

  it('exige o nome e emite os atributos do funil', async () => {
    const wrapper = mountDialog(null);
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeDefined();
    await wrapper.find('[data-test="pipeline-name"]').setValue(' Parcerias ');
    await wrapper.find('[data-test="confirm"]').trigger('click');

    expect(wrapper.emitted('submit')).toEqual([
      [
        {
          id: undefined,
          attributes: {
            name: 'Parcerias',
            description: null,
            is_default: false,
          },
        },
      ],
    ]);
  });
});
