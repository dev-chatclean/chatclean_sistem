import { DAY_IN_SECONDS } from './constants';
import { staleLevel } from './dealHelpers';

const normalize = value =>
  String(value || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

const MIN_DIGITS_SEARCH = 3;

const nowInSeconds = () => Math.floor(Date.now() / 1000);

const dateToSeconds = (value, endOfDay = false) => {
  if (!value) return null;
  const date = new Date(`${value}T${endOfDay ? '23:59:59' : '00:00:00'}`);
  return Math.floor(date.getTime() / 1000);
};

const inDateRange = (seconds, { from, to }) => {
  if (seconds == null) return false;
  const start = dateToSeconds(from);
  const end = dateToSeconds(to, true);
  return (start == null || seconds >= start) && (end == null || seconds <= end);
};

const isSameDay = (seconds, date) =>
  new Date(seconds * 1000).toDateString() === date.toDateString();

const ACTIVITY_MATCHERS = {
  overdue: due => due != null && due < nowInSeconds(),
  today: due => due != null && isSameDay(due, new Date()),
  upcoming: due => due != null && due >= nowInSeconds(),
  none: due => due == null,
};

const nextActivityDue = deal => deal.next_activity?.due_at ?? null;

const expectedCloseSeconds = deal =>
  deal.expected_close_date ? dateToSeconds(deal.expected_close_date) : null;

const FILTER_MATCHERS = {
  assignee: (deal, value) => deal.assignee.id === value,
  label: (deal, value) => Boolean(deal.contact?.labels.includes(value)),
  lead_origin: (deal, value) => deal.lead_origin === value,
  channel: (deal, value) => deal.conversation?.inbox_id === value,
  status: (deal, value) => deal.status === value,
  loss_reason: (deal, value) =>
    deal.status === 'lost' && deal.close_reason === value,
  stage: (deal, value) => deal.stage_id === value,
  value: (deal, { min, max }) =>
    (min === '' || min == null || deal.value >= Number(min)) &&
    (max === '' || max == null || deal.value <= Number(max)),
  activities: (deal, value) => ACTIVITY_MATCHERS[value](nextActivityDue(deal)),
  stale: (deal, _value, stagesById) =>
    staleLevel(deal, stagesById[deal.stage_id]) === 'danger',
  contact: (deal, value) =>
    normalize(
      [
        deal.contact?.name,
        deal.contact?.phone_number,
        deal.contact?.email,
      ].join(' ')
    ).includes(normalize(value)),
  company: (deal, value) =>
    normalize(deal.company?.name).includes(normalize(value)),
  title: (deal, value) => normalize(deal.title).includes(normalize(value)),
  created_at: (deal, value) => inDateRange(deal.created_at, value),
  stage_entered_at: (deal, value) => inDateRange(deal.stage_entered_at, value),
  expected_close_date: (deal, value) =>
    inDateRange(expectedCloseSeconds(deal), value),
};

const SORTERS = {
  longest_in_stage: (a, b) => a.stage_entered_at - b.stage_entered_at,
  recently_moved: (a, b) => b.stage_entered_at - a.stage_entered_at,
  recently_created: (a, b) => b.created_at - a.created_at,
  oldest_created: (a, b) => a.created_at - b.created_at,
  highest_value: (a, b) => b.value - a.value,
  lowest_value: (a, b) => a.value - b.value,
  next_activity: (a, b) =>
    (nextActivityDue(a) ?? Infinity) - (nextActivityDue(b) ?? Infinity),
};

const matchesSearch = (deal, search) => {
  const term = normalize(search.trim());
  if (!term) return true;
  const haystack = normalize(
    [
      deal.display_name,
      deal.title,
      deal.contact?.name,
      deal.contact?.phone_number,
      deal.contact?.email,
      deal.company?.name,
      `#${deal.number}`,
    ].join(' ')
  );
  const digits = term.replace(/\D/g, '');
  return (
    haystack.includes(term) ||
    (digits.length >= MIN_DIGITS_SEARCH &&
      haystack.replace(/\D/g, '').includes(digits))
  );
};

const matchesPeriod = (deal, state) => {
  if (deal.status === 'open') {
    if (state.openPeriod === 'any') return true;
    if (state.openPeriod === 'custom')
      return inDateRange(deal.created_at, state.customRange);
    return (
      deal.created_at >= nowInSeconds() - state.openPeriod * DAY_IN_SECONDS
    );
  }
  if (state.view === 'all') return true;
  return deal.closed_at >= nowInSeconds() - state.closedPeriod * DAY_IN_SECONDS;
};

export const applyBoardFilters = (deals, state, stages) => {
  const stagesById = Object.fromEntries(stages.map(stage => [stage.id, stage]));
  return deals
    .filter(deal => matchesSearch(deal, state.search))
    .filter(deal => matchesPeriod(deal, state))
    .filter(deal =>
      state.filters.every(({ field, value }) =>
        FILTER_MATCHERS[field](deal, value, stagesById)
      )
    )
    .sort(SORTERS[state.sort]);
};

export const defaultBoardState = () => ({
  search: '',
  view: 'open',
  sort: 'longest_in_stage',
  openPeriod: 'any',
  customRange: { from: '', to: '' },
  closedPeriod: 30,
  filters: [],
});
