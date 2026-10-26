import { mount, flushPromises } from '@vue/test-utils';
import ScheduleTab from '../ScheduleTab.vue';
import WorkingScheduleAPI from 'dashboard/api/chatclean/workingSchedule';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/chatclean/workingSchedule', () => ({
  default: { show: vi.fn(), save: vi.fn() },
}));

const WEEK = [0, 1, 2, 3, 4, 5, 6].map(day => ({
  day_of_week: day,
  closed_all_day: day === 0,
  open_all_day: false,
  open_hour: 8,
  open_minutes: 0,
  close_hour: 18,
  close_minutes: 0,
}));
const SCHEDULE = {
  mode: 'per_channel',
  enabled: false,
  timezone: 'America/Sao_Paulo',
  out_of_office_message: '',
  working_hours: WEEK,
};

const mountTab = async () => {
  WorkingScheduleAPI.show.mockResolvedValue({ data: SCHEDULE });
  const wrapper = mount(ScheduleTab, {
    global: { stubs: { BusinessDay: true, ComboBox: true } },
  });
  await flushPromises();
  return wrapper;
};

describe('ScheduleTab', () => {
  it('shows the account hours only in per account mode with business hours on', async () => {
    const wrapper = await mountTab();
    expect(wrapper.find('[data-test="schedule-enabled"]').exists()).toBe(false);

    await wrapper.find('select').setValue('per_account');
    expect(wrapper.find('[data-test="schedule-enabled"]').exists()).toBe(true);
    expect(wrapper.findAll('business-day-stub')).toHaveLength(0);

    await wrapper
      .find(
        '[data-test="schedule-enabled"] button, button[data-test="schedule-enabled"]'
      )
      .trigger('click');
    expect(wrapper.findAll('business-day-stub')).toHaveLength(7);
  });

  it('saves the mode, timezone, message and the seven days', async () => {
    WorkingScheduleAPI.save.mockResolvedValue({
      data: { ...SCHEDULE, mode: 'per_account' },
    });
    const wrapper = await mountTab();

    await wrapper.find('select').setValue('per_account');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(WorkingScheduleAPI.save).toHaveBeenCalledWith(
      expect.objectContaining({
        mode: 'per_account',
        timezone: 'America/Sao_Paulo',
        working_hours: expect.arrayContaining([
          expect.objectContaining({
            day_of_week: 1,
            open_hour: 8,
            close_hour: 18,
          }),
          expect.objectContaining({ day_of_week: 0, closed_all_day: true }),
        ]),
      })
    );
  });
});
