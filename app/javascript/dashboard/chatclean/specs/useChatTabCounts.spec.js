import { ref } from 'vue';
import { flushPromises } from '@vue/test-utils';
import { useChatTabCounts } from '../conversation/useChatTabCounts';
import ConversationApi from 'dashboard/api/inbox/conversation';

vi.mock('dashboard/composables/emitter', () => ({ useEmitter: vi.fn() }));
vi.mock('dashboard/api/inbox/conversation', () => ({
  default: { meta: vi.fn() },
}));

const meta = counts => ({ data: { meta: counts } });

describe('useChatTabCounts', () => {
  it('counts the open conversations for Ativos and Pendentes and the closed ones for Fechados', async () => {
    ConversationApi.meta.mockImplementation(({ status }) =>
      Promise.resolve(
        status === 'open'
          ? meta({ mine_count: 3, unassigned_count: 2, all_count: 9 })
          : meta({ mine_count: 0, unassigned_count: 0, all_count: 0 })
      )
    );
    const filters = ref({ inboxId: 4, teamId: 7, status: 'resolved' });

    const counts = useChatTabCounts(filters);
    await flushPromises();

    expect(ConversationApi.meta).toHaveBeenCalledWith(
      expect.objectContaining({ inboxId: 4, teamId: 7, status: 'open' })
    );
    expect(ConversationApi.meta).toHaveBeenCalledWith(
      expect.objectContaining({ inboxId: 4, teamId: 7, status: 'resolved' })
    );
    expect(counts).toEqual({
      mineCount: 3,
      unAssignedCount: 2,
      closedCount: 0,
    });
  });
});
