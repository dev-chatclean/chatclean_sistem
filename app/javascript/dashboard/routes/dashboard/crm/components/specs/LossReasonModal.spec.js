import { mount } from '@vue/test-utils';
import LossReasonModal from '../LossReasonModal.vue';

const DialogStub = {
  props: ['disableConfirmButton', 'description'],
  emits: ['confirm', 'close'],
  methods: {
    open: vi.fn(),
    close() {
      this.$emit('close');
    },
  },
  template:
    '<div><p data-test="description">{{ description }}</p><slot /><button data-test="confirm" :disabled="disableConfirmButton" @click="$emit(\'confirm\')" /></div>',
};

const SelectStub = {
  props: ['modelValue', 'options'],
  emits: ['update:modelValue'],
  template:
    '<select :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option value="" /><option v-for="o in options" :key="o.value" :value="o.value">{{ o.label }}</option></select>',
};

const mountModal = (props = {}) =>
  mount(LossReasonModal, {
    props: {
      dealTitle: 'Plano anual',
      lossReasons: [
        { id: 5, name: 'Preço' },
        { id: 6, name: 'Concorrente' },
      ],
      ...props,
    },
    global: {
      stubs: {
        Dialog: DialogStub,
        Select: SelectStub,
        TextArea: {
          props: ['modelValue'],
          emits: ['update:modelValue'],
          template:
            '<textarea data-test="details" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
      },
    },
  });

describe('LossReasonModal', () => {
  it('só libera a confirmação depois de escolher um motivo', async () => {
    const wrapper = mountModal();
    wrapper.vm.open();
    await wrapper.vm.$nextTick();

    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeDefined();
    await wrapper.find('[data-test="loss-reason"]').setValue('6');
    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeUndefined();
  });

  it('emite confirm com o motivo e o detalhe sem espaços nas pontas', async () => {
    const wrapper = mountModal();
    wrapper.vm.open();
    await wrapper.find('[data-test="loss-reason"]').setValue('5');
    await wrapper.find('[data-test="details"]').setValue('  achou caro  ');
    await wrapper.find('[data-test="confirm"]').trigger('click');

    expect(wrapper.emitted('confirm')).toEqual([
      [{ lossReasonId: 5, lossDetails: 'achou caro' }],
    ]);
  });

  it('emite cancel ao fechar sem confirmar, mas não depois de confirmar', async () => {
    const wrapper = mountModal();
    wrapper.vm.open();
    wrapper.vm.close();
    expect(wrapper.emitted('cancel')).toHaveLength(1);

    wrapper.vm.open();
    await wrapper.find('[data-test="loss-reason"]').setValue('5');
    await wrapper.find('[data-test="confirm"]').trigger('click');
    wrapper.vm.close();
    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('avisa quando não há motivos ativos', () => {
    const wrapper = mountModal({ lossReasons: [] });

    expect(wrapper.text()).toContain('CRM.KANBAN.LOSS_MODAL.NO_REASONS');
  });
});
