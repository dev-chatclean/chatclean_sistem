import { computed } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import StartConversationDialog from '../conversation/StartConversationDialog.vue';
import ConversationApi from 'dashboard/api/conversations';
import { createNewContact } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';

const push = vi.fn();
const INBOXES = [
  { id: 1, name: 'Site', channel_type: 'Channel::WebWidget' },
  { id: 2, name: 'WhatsApp QR', channel_type: 'Channel::Api' },
  { id: 3, name: 'WhatsApp oficial', channel_type: 'Channel::Whatsapp' },
];
const GETTERS = {
  getCurrentUser: { id: 9 },
  getCurrentAccountId: 1,
  'inboxes/getInboxes': INBOXES,
  'teams/getTeams': [{ id: 5, name: 'Vendas' }],
};

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('vue-router', () => ({ useRouter: () => ({ push }) }));
vi.mock('@chatwoot/utils', () => ({ debounce: fn => fn }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: key => computed(() => GETTERS[key]),
}));
vi.mock('dashboard/api/conversations', () => ({
  default: { create: vi.fn() },
}));
vi.mock(
  'dashboard/components-next/NewConversation/helpers/composeConversationHelper',
  () => ({
    createContactSearcher: () => vi.fn().mockResolvedValue([]),
    createNewContact: vi.fn(),
    fetchContactableInboxes: vi.fn().mockResolvedValue([]),
  })
);

const mountDialog = () =>
  mount(StartConversationDialog, {
    global: {
      stubs: {
        Dialog: {
          props: ['disableConfirmButton', 'showConfirmButton'],
          template:
            '<div><slot /><button v-if="showConfirmButton !== false" data-test="confirm" :disabled="disableConfirmButton" @click="$emit(\'confirm\')" /></div>',
          methods: { open: vi.fn(), close: vi.fn() },
        },
        PhoneNumberInput: {
          props: ['modelValue'],
          template:
            '<input data-test="phone" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
        WhatsAppOptions: { template: '<div data-test="templates" />' },
        EmojiIconPicker: true,
      },
      directives: { onClickaway: {} },
    },
  });

describe('StartConversationDialog', () => {
  it('offers only the phone inboxes for a new number and starts the conversation assigned to whoever started it', async () => {
    createNewContact.mockResolvedValue({ id: 42 });
    ConversationApi.create.mockResolvedValue({ data: { id: 77 } });
    const wrapper = mountDialog();

    await wrapper.find('[data-test="start-phone"]').setValue('+5584999887766');
    await flushPromises();
    const options = wrapper
      .findAll('select')[0]
      .findAll('option')
      .map(option => option.text());
    expect(options).toEqual(
      expect.arrayContaining(['WhatsApp QR', 'WhatsApp oficial'])
    );
    expect(options).not.toContain('Site');

    await wrapper.findAll('select')[0].setValue(2);
    await wrapper.findAll('select')[1].setValue(5);
    await wrapper.find('textarea').setValue('Olá!');
    await wrapper.find('[data-test="confirm"]').trigger('click');
    await flushPromises();

    expect(createNewContact).toHaveBeenCalledWith('+5584999887766');
    expect(ConversationApi.create).toHaveBeenCalledWith(
      expect.objectContaining({
        inbox_id: 2,
        contact_id: 42,
        assignee_id: 9,
        team_id: 5,
        message: { content: 'Olá!' },
      })
    );
    expect(push).toHaveBeenCalledWith('/app/accounts/1/conversations/77');
  });

  it('asks for a template instead of free text on the official WhatsApp', async () => {
    const wrapper = mountDialog();

    await wrapper.find('[data-test="start-phone"]').setValue('+5584999887766');
    await flushPromises();
    await wrapper.findAll('select')[0].setValue(3);

    expect(wrapper.find('[data-test="templates"]').exists()).toBe(true);
    expect(wrapper.find('textarea').exists()).toBe(false);
    expect(wrapper.find('[data-test="confirm"]').exists()).toBe(false);
  });
});
