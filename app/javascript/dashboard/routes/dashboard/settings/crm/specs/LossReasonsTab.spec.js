import { mount } from '@vue/test-utils';
import { setActivePinia, createPinia } from 'pinia';
import { useCrmSettingsStore } from 'dashboard/stores/crmSettings';
import LossReasonsTab from '../LossReasonsTab.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

let crm;
const dialogOpen = vi.fn();

const mountTab = () =>
  mount(LossReasonsTab, {
    global: {
      stubs: {
        BaseTable: {
          props: ['items'],
          template: '<table><slot name="row" :items="items" /></table>',
        },
        BaseTableRow: { template: '<tr data-test="row"><slot /></tr>' },
        BaseTableCell: { template: '<td><slot /></td>' },
        Switch: {
          props: ['modelValue', 'disabled'],
          emits: ['update:modelValue'],
          template:
            '<button data-test="active-switch" :disabled="disabled" @click="$emit(\'update:modelValue\', !modelValue)" />',
        },
        Button: {
          emits: ['click'],
          template:
            '<button data-test="edit-reason" @click="$emit(\'click\')" />',
        },
        Spinner: true,
        LossReasonDialog: {
          methods: { open: dialogOpen, close: vi.fn() },
          template: '<div />',
        },
      },
    },
  });

describe('LossReasonsTab', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    crm = useCrmSettingsStore();
    crm.fetchLossReasons = vi.fn().mockResolvedValue();
    crm.updateLossReason = vi.fn().mockResolvedValue();
    crm.lossReasons = [
      { id: 1, name: 'Contato bloqueado', isActive: true, isSystem: true },
      { id: 2, name: 'Preço', isActive: true, isSystem: false },
    ];
  });

  it('marca o motivo de sistema e trava o switch dele', () => {
    const rows = mountTab().findAll('[data-test="row"]');

    expect(rows[0].find('[data-test="system-tag"]').exists()).toBe(true);
    expect(
      rows[0].find('[data-test="active-switch"]').attributes('disabled')
    ).toBeDefined();
    expect(rows[1].find('[data-test="system-tag"]').exists()).toBe(false);
    expect(
      rows[1].find('[data-test="active-switch"]').attributes('disabled')
    ).toBeUndefined();
  });

  it('desativa um motivo comum pelo switch', async () => {
    const rows = mountTab().findAll('[data-test="row"]');

    await rows[1].find('[data-test="active-switch"]').trigger('click');

    expect(crm.updateLossReason).toHaveBeenCalledWith(2, { is_active: false });
  });

  it('abre a edição com os dados do motivo, inclusive o de sistema', async () => {
    const rows = mountTab().findAll('[data-test="row"]');

    await rows[0].find('[data-test="edit-reason"]').trigger('click');

    expect(dialogOpen).toHaveBeenCalledWith(crm.lossReasons[0]);
  });
});
