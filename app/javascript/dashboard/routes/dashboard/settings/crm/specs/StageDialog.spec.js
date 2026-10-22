import { mount } from '@vue/test-utils';
import StageDialog from '../StageDialog.vue';

const mountDialog = () =>
  mount(StageDialog, {
    global: {
      stubs: {
        Dialog: {
          props: ['disableConfirmButton'],
          emits: ['confirm'],
          methods: { open: vi.fn(), close: vi.fn() },
          template:
            '<div><slot /><button data-test="confirm" :disabled="disableConfirmButton" @click="$emit(\'confirm\')" /></div>',
        },
        Input: {
          props: ['modelValue', 'disabled', 'type'],
          emits: ['update:modelValue'],
          template:
            '<input :value="modelValue" :disabled="disabled" @input="$emit(\'update:modelValue\', type === \'number\' && $event.target.value !== \'\' ? Number($event.target.value) : $event.target.value)" />',
        },
      },
    },
  });

describe('StageDialog', () => {
  it('cria estágio com nome e probabilidade inteira de 0 a 100', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();
    await wrapper.find('[data-test="stage-name"]').setValue('Proposta');

    await wrapper.find('[data-test="stage-probability"]').setValue('150');
    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeDefined();

    await wrapper.find('[data-test="stage-probability"]').setValue('40');
    await wrapper.find('[data-test="confirm"]').trigger('click');

    expect(wrapper.emitted('submit')).toEqual([
      [{ id: undefined, attributes: { name: 'Proposta', probability: 40 } }],
    ]);
  });

  it('em Ganho e Perdido trava a probabilidade e envia só o nome', async () => {
    const wrapper = mountDialog();
    wrapper.vm.open({ id: 3, name: 'Ganho', status: 'won', probability: 100 });
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="stage-probability"]').attributes('disabled')
    ).toBeDefined();
    await wrapper.find('[data-test="stage-name"]').setValue('Fechado');
    await wrapper.find('[data-test="confirm"]').trigger('click');

    expect(wrapper.emitted('submit')).toEqual([
      [{ id: 3, attributes: { name: 'Fechado' } }],
    ]);
  });
});
