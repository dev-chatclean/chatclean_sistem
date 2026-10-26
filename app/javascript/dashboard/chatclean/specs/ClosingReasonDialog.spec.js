import { mount, flushPromises } from '@vue/test-utils';
import ClosingReasonDialog from '../closing/ClosingReasonDialog.vue';
import { askClosingReason, closingRequest } from '../closing/closingRequest';
import ClosingReasonsAPI from 'dashboard/api/chatclean/closingReasons';

const alert = vi.fn();

vi.mock('dashboard/composables', () => ({
  useAlert: message => alert(message),
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/api/chatclean/closingReasons', () => ({
  default: { getActive: vi.fn() },
}));

const REASONS = [
  { id: 1, name: 'Resolvido', ask_sale_value: false },
  { id: 2, name: 'Venda', ask_sale_value: true },
];

const DialogStub = {
  props: ['disableConfirmButton'],
  emits: ['confirm', 'close'],
  template:
    '<div><slot /><button data-test="confirm" :disabled="disableConfirmButton" @click="$emit(\'confirm\')" /></div>',
  methods: {
    open: vi.fn(),
    close() {
      this.$emit('close');
    },
  },
};

let wrapper;

const mountDialog = () => {
  wrapper = mount(ClosingReasonDialog, {
    global: { stubs: { Dialog: DialogStub } },
  });
  return wrapper;
};

// Abre a janela e devolve a promessa do pedido, sem esperar a resposta da pessoa.
const openWith = async (reasons, submit = vi.fn()) => {
  ClosingReasonsAPI.getActive.mockResolvedValue({ data: { payload: reasons } });
  const result = askClosingReason({ submit });
  await flushPromises();
  return { result };
};

describe('ClosingReasonDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    closingRequest.isOpen = false;
  });

  afterEach(() => wrapper.unmount());

  it('blocks the closing when there is no active reason', async () => {
    mountDialog();
    await openWith([]);

    expect(wrapper.find('[data-test="closing-no-reasons"]').exists()).toBe(
      true
    );
    expect(
      wrapper.find('[data-test="confirm"]').attributes('disabled')
    ).toBeDefined();
  });

  it('asks the sale value only for a reason that requires it and closes with it', async () => {
    mountDialog();
    const submit = vi.fn().mockResolvedValue();
    const { result } = await openWith(REASONS, submit);

    await wrapper.find('select').setValue(2);
    const confirm = wrapper.find('[data-test="confirm"]');
    expect(confirm.attributes('disabled')).toBeDefined();

    await wrapper.find('input[type="number"]').setValue('150.5');
    await confirm.trigger('click');
    await flushPromises();

    expect(submit).toHaveBeenCalledWith({
      closingReasonId: 2,
      saleValue: 150.5,
    });
    expect(await result).toBe(true);
  });

  it('closes with a reason without sale value', async () => {
    mountDialog();
    const submit = vi.fn().mockResolvedValue();
    await openWith(REASONS, submit);

    await wrapper.find('select').setValue(1);
    expect(wrapper.find('input[type="number"]').exists()).toBe(false);
    await wrapper.find('[data-test="confirm"]').trigger('click');
    await flushPromises();

    expect(submit).toHaveBeenCalledWith({
      closingReasonId: 1,
      saleValue: null,
    });
  });

  it('shows the server error and reloads the reasons when the closing is refused', async () => {
    mountDialog();
    const submit = vi
      .fn()
      .mockRejectedValue({ response: { data: { error: 'Motivo inativo' } } });
    await openWith(REASONS, submit);

    await wrapper.find('select').setValue(1);
    await wrapper.find('[data-test="confirm"]').trigger('click');
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('Motivo inativo');
    expect(ClosingReasonsAPI.getActive).toHaveBeenCalledTimes(2);
    expect(closingRequest.isOpen).toBe(true);
  });

  it('resolves false when the person gives up', async () => {
    mountDialog();
    const { result } = await openWith(REASONS);

    wrapper.findComponent(DialogStub).vm.close();

    expect(await result).toBe(false);
    expect(closingRequest.isOpen).toBe(false);
  });
});
