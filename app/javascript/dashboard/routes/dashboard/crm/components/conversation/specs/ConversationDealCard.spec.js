import { mount } from '@vue/test-utils';
import ConversationDealCard from '../ConversationDealCard.vue';

const pipeline = {
  id: 1,
  name: 'Vendas',
  stages: [
    { id: 10, name: 'Novo', status: 'open' },
    { id: 11, name: 'Ganho', status: 'won' },
    { id: 12, name: 'Perdido', status: 'lost' },
  ],
};

const deal = {
  id: 7,
  title: 'Plano anual',
  value: '990',
  crmStageId: 10,
  assigneeId: null,
  assignee: null,
};

const mountCard = props =>
  mount(ConversationDealCard, {
    props: { deal, pipeline, agents: [{ id: 3, name: 'Ana' }], ...props },
    global: {
      stubs: {
        Avatar: true,
        Icon: true,
        DropdownMenu: {
          props: ['menuItems'],
          emits: ['action'],
          template:
            '<ul><li v-for="item in menuItems" :key="String(item.value)" @click="$emit(\'action\', item)">{{ item.label }}</li></ul>',
        },
        Select: {
          props: ['modelValue', 'options', 'disabled'],
          emits: ['update:modelValue'],
          template:
            '<select :value="modelValue" :disabled="disabled" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="o in options" :key="o.value" :value="o.value">{{ o.label }}</option></select>',
        },
      },
    },
  });

describe('ConversationDealCard', () => {
  it('mostra valor em reais, funil e estágio', () => {
    const wrapper = mountCard();

    expect(wrapper.text()).toMatch(/R\$\s990,00/);
    expect(wrapper.find('[data-test="pipeline-stage"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="current-conversation"]').exists()).toBe(
      false
    );
  });

  it('marca o deal da conversa aberta', () => {
    expect(
      mountCard({ isCurrentConversation: true })
        .find('[data-test="current-conversation"]')
        .exists()
    ).toBe(true);
  });

  it('emite a troca de estágio com o id numérico', async () => {
    const wrapper = mountCard();

    await wrapper.find('select').setValue('12');

    expect(wrapper.emitted('changeStage')).toEqual([[12]]);
  });

  it('emite a troca de responsável', async () => {
    const wrapper = mountCard();

    await wrapper.find('[data-test="assignee"]').trigger('click');
    await wrapper.find('li').trigger('click');

    expect(wrapper.emitted('assign')).toEqual([[3]]);
  });

  it('trava estágio e responsável quando o contato está bloqueado', () => {
    const wrapper = mountCard({ locked: true });

    expect(wrapper.find('select').attributes('disabled')).toBeDefined();
    expect(
      wrapper.find('[data-test="assignee"]').attributes('disabled')
    ).toBeDefined();
  });
});
