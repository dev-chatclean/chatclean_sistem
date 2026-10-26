import { mount } from '@vue/test-utils';
import { computed } from 'vue';
import CannedScopeFields from '../canned/CannedScopeFields.vue';
import {
  buildCannedFormData,
  MAX_ATTACHMENTS_SIZE,
} from '../canned/cannedResponseForm';

let isAdmin = true;

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: computed(() => isAdmin) }),
}));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => computed(() => [{ id: 5, name: 'Vendas' }]),
}));

describe('buildCannedFormData', () => {
  it('sends the teams only for the Teams visibility, plus new and removed files', () => {
    const file = new File(['x'], 'tabela.pdf');
    const data = buildCannedFormData({
      shortCode: 'tabela',
      content: 'Segue',
      visibility: 'teams',
      teamIds: [5],
      newFiles: [file],
      removeAttachmentIds: [9],
    });

    expect(data.get('canned_response[visibility]')).toBe('teams');
    expect(data.getAll('canned_response[team_ids][]')).toEqual(['5']);
    expect(data.getAll('canned_response[attachments][]')).toEqual([file]);
    expect(data.getAll('canned_response[remove_attachment_ids][]')).toEqual([
      '9',
    ]);

    const personal = buildCannedFormData({
      shortCode: 'oi',
      content: 'Oi',
      visibility: 'personal',
      teamIds: [5],
    });
    expect(personal.getAll('canned_response[team_ids][]')).toEqual([]);
  });
});

describe('CannedScopeFields', () => {
  const mountFields = props =>
    mount(CannedScopeFields, {
      props,
      global: { stubs: { TagMultiSelectComboBox: true } },
    });

  it('lets only the administrator choose who sees it', () => {
    isAdmin = true;
    expect(mountFields().find('[data-test="canned-visibility"]').exists()).toBe(
      true
    );

    isAdmin = false;
    const agentFields = mountFields();
    expect(agentFields.find('[data-test="canned-visibility"]').exists()).toBe(
      false
    );
    expect(
      agentFields.find('[data-test="canned-personal-only"]').exists()
    ).toBe(true);
  });

  it('warns and flags the form when the attachments pass 16 MB in total', async () => {
    isAdmin = true;
    const wrapper = mountFields({
      existingAttachments: [
        { id: 1, file_name: 'grande.pdf', file_size: MAX_ATTACHMENTS_SIZE },
      ],
      newFiles: [new File(['x'], 'mais.pdf')],
    });
    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-test="canned-over-limit"]').exists()).toBe(true);
    expect(wrapper.emitted('update:overLimit').at(-1)).toEqual([true]);
  });
});
