import { mount, flushPromises } from '@vue/test-utils';
import QueueActions from '../conversation/QueueActions.vue';
import ChatcleanConversationsAPI from 'dashboard/api/chatclean/conversations';

const dispatch = vi.fn();
const alert = vi.fn();

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
}));
vi.mock('dashboard/composables', () => ({
  useAlert: message => alert(message),
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/api/chatclean/conversations', () => ({
  default: { accept: vi.fn() },
}));

const mountActions = chat =>
  mount(QueueActions, {
    props: { chat: { id: 7, inbox_id: 2, meta: {}, ...chat } },
    global: {
      stubs: {
        TransferDialog: { template: '<div />', methods: { open: vi.fn() } },
      },
    },
  });

describe('QueueActions', () => {
  beforeEach(() => {
    dispatch.mockReset();
    alert.mockReset();
  });

  it('offers Accept for a conversation without agent and Queue once it has one', () => {
    expect(
      mountActions().find('[data-test="conversation-accept"]').exists()
    ).toBe(true);

    const assigned = mountActions({ meta: { assignee: { id: 1 } } });
    expect(assigned.find('[data-test="conversation-accept"]').exists()).toBe(
      false
    );
    expect(assigned.find('[data-test="conversation-queue"]').exists()).toBe(
      true
    );
    expect(assigned.find('[data-test="conversation-transfer"]').exists()).toBe(
      true
    );
  });

  it('accepts the conversation and shows who got it first when it is taken', async () => {
    ChatcleanConversationsAPI.accept.mockResolvedValueOnce({
      data: { id: 3, name: 'Ana' },
    });
    const wrapper = mountActions();

    await wrapper.find('[data-test="conversation-accept"]').trigger('click');
    await flushPromises();
    expect(dispatch).toHaveBeenCalledWith('setCurrentChatAssignee', {
      conversationId: 7,
      assignee: { id: 3, name: 'Ana' },
    });

    ChatcleanConversationsAPI.accept.mockRejectedValueOnce({
      response: { data: { error: 'Atendimento já aceito por Bruno' } },
    });
    await wrapper.find('[data-test="conversation-accept"]').trigger('click');
    await flushPromises();
    expect(alert).toHaveBeenLastCalledWith('Atendimento já aceito por Bruno');
  });

  it('sends the conversation back to the pending queue', async () => {
    const wrapper = mountActions({ meta: { assignee: { id: 1 } } });

    await wrapper.find('[data-test="conversation-queue"]').trigger('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('assignAgent', {
      conversationId: 7,
      agentId: null,
    });
  });
});
