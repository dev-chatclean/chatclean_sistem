import { mount } from '@vue/test-utils';
import { ref } from 'vue';
import TopBar from '../TopBar.vue';

const unread = ref(0);

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => unread,
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountScopedRoute: name => ({ name }) }),
}));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const mountBar = () =>
  mount(TopBar, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a><slot /></a>' },
        SidebarProfileMenu: true,
      },
    },
  });

describe('TopBar', () => {
  beforeEach(() => {
    unread.value = 0;
  });

  it('shows the conversations shortcut, the notifications and the profile', () => {
    const wrapper = mountBar();

    expect(wrapper.find('[data-test="top-bar-conversations"]').text()).toBe(
      'CHATCLEAN.TOP_BAR.CONVERSATIONS'
    );
    expect(wrapper.find('[data-test="top-bar-notifications"]').exists()).toBe(
      true
    );
    expect(wrapper.findComponent({ name: 'SidebarProfileMenu' }).exists()).toBe(
      true
    );
    expect(
      wrapper.find('[data-test="top-bar-notifications-badge"]').exists()
    ).toBe(false);
  });

  it('counts the unread notifications, up to 99+', async () => {
    unread.value = 3;
    const wrapper = mountBar();
    expect(
      wrapper.find('[data-test="top-bar-notifications-badge"]').text()
    ).toBe('3');

    unread.value = 150;
    await wrapper.vm.$nextTick();
    expect(
      wrapper.find('[data-test="top-bar-notifications-badge"]').text()
    ).toBe('99+');
  });
});
