import { mount } from '@vue/test-utils';
import DealCard from '../DealCard.vue';

const buildDeal = overrides => ({
  id: 7,
  title: 'Plano anual',
  value: '1500.5',
  assigneeId: null,
  assignee: null,
  conversationDisplayId: 42,
  contact: { id: 3, name: 'Maria', blocked: false },
  ...overrides,
});

const mountCard = (deal, agents = []) =>
  mount(DealCard, {
    props: { deal, agents },
    global: {
      stubs: {
        Avatar: true,
        Icon: true,
        RouterLink: {
          props: ['to'],
          template: '<a :data-to="JSON.stringify(to)"><slot /></a>',
        },
        DropdownMenu: {
          props: ['menuItems'],
          emits: ['action'],
          template:
            '<ul data-test="menu"><li v-for="item in menuItems" :key="String(item.value)" @click="$emit(\'action\', item)">{{ item.label }}</li></ul>',
        },
      },
    },
  });

describe('DealCard', () => {
  it('mostra título, valor em reais, contato e "sem responsável"', () => {
    const wrapper = mountCard(buildDeal());

    expect(wrapper.text()).toContain('Plano anual');
    expect(wrapper.text()).toMatch(/R\$\s1\.500,50/);
    expect(wrapper.text()).toContain('Maria');
    expect(wrapper.text()).toContain('CRM.KANBAN.CARD.UNASSIGNED');
    expect(wrapper.text()).not.toContain('CRM.KANBAN.CARD.BLOCKED_CONTACT');
  });

  it('aponta o atalho para a conversa pelo display_id', () => {
    const link = mountCard(buildDeal()).find('[data-test="open-conversation"]');

    expect(JSON.parse(link.attributes('data-to'))).toEqual({
      name: 'inbox_conversation',
      params: { conversation_id: 42 },
    });
  });

  it('esconde o atalho quando o deal não tem conversa', () => {
    const wrapper = mountCard(buildDeal({ conversationDisplayId: null }));

    expect(wrapper.find('[data-test="open-conversation"]').exists()).toBe(
      false
    );
  });

  it('marca o contato bloqueado', () => {
    const wrapper = mountCard(
      buildDeal({ contact: { id: 3, name: 'Maria', blocked: true } })
    );

    expect(wrapper.text()).toContain('CRM.KANBAN.CARD.BLOCKED_CONTACT');
  });

  it('emite assign com o agente escolhido e com null ao remover', async () => {
    const agents = [
      { id: 1, name: 'Ana' },
      { id: 2, name: 'Bruno' },
    ];
    const wrapper = mountCard(
      buildDeal({ assigneeId: 1, assignee: { id: 1, name: 'Ana' } }),
      agents
    );

    await wrapper.find('[data-test="assignee"]').trigger('click');
    const items = wrapper.findAll('[data-test="menu"] li');
    expect(items.map(item => item.text())).toEqual([
      'Ana',
      'Bruno',
      'CRM.KANBAN.CARD.REMOVE_ASSIGNEE',
    ]);

    await items[1].trigger('click');
    await wrapper.find('[data-test="assignee"]').trigger('click');
    await wrapper.findAll('[data-test="menu"] li')[2].trigger('click');

    expect(wrapper.emitted('assign')).toEqual([[2], [null]]);
  });

  it('não emite assign ao escolher o responsável atual', async () => {
    const wrapper = mountCard(
      buildDeal({ assigneeId: 1, assignee: { id: 1, name: 'Ana' } }),
      [{ id: 1, name: 'Ana' }]
    );

    await wrapper.find('[data-test="assignee"]').trigger('click');
    await wrapper.find('[data-test="menu"] li').trigger('click');

    expect(wrapper.emitted('assign')).toBeUndefined();
  });
});
