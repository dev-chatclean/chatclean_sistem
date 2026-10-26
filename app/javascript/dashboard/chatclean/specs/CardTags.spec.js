import { mount } from '@vue/test-utils';
import CardTags from '../conversation/CardTags.vue';

const mountTags = props =>
  mount(CardTags, {
    props: { displayId: 42, ...props },
    global: { stubs: { ChannelIcon: true, Icon: true } },
  });

describe('CardTags', () => {
  it('shows the number, the channel, the agent and the team', () => {
    const wrapper = mountTags({
      inbox: { name: 'WhatsApp Vendas' },
      assignee: { name: 'Ana' },
      team: { name: 'Comercial' },
    });

    expect(wrapper.text()).toContain('#42');
    expect(wrapper.find('[data-test="card-tag-channel"]').text()).toBe(
      'WhatsApp Vendas'
    );
    expect(wrapper.find('[data-test="card-tag-agent"]').text()).toBe('Ana');
    expect(wrapper.find('[data-test="card-tag-team"]').text()).toBe(
      'Comercial'
    );
  });

  it('uses the bot icon when the assignee is a bot', () => {
    const wrapper = mount(CardTags, {
      props: { displayId: 1, assignee: { name: 'Bot' }, assigneeIsBot: true },
      global: { stubs: { ChannelIcon: true } },
    });

    expect(wrapper.findComponent({ name: 'Icon' }).props('icon')).toBe(
      'i-lucide-bot'
    );
  });

  it('leaves out the agent and the team when there are none', () => {
    const wrapper = mountTags({ inbox: { name: 'Site' } });

    expect(wrapper.find('[data-test="card-tag-agent"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="card-tag-team"]').exists()).toBe(false);
  });
});
