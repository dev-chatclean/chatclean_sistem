// Names, colors and dates shown by the Visão geral report, on the page and in the CSV.
export const CHANNEL_COLORS = {
  whatsapp: 'rgb(var(--teal-9))',
  instagram: 'rgb(var(--ruby-9))',
  messenger: 'rgb(var(--iris-9))',
  site: 'rgb(var(--amber-9))',
  email: 'rgb(var(--slate-9))',
};
export const OTHER_CHANNEL_COLOR = 'rgb(var(--slate-7))';

export const channelKindLabel = (key, t) =>
  t(`CRM_REPORTS.OVERVIEW.CHANNELS.${key.toUpperCase()}`);

const utcDate = date => new Date(`${date}T00:00:00Z`);
const localeTag = locale => locale.replace('_', '-');

// "seg., 09/11": the day with its weekday, for the best day and the table.
export const dayWithWeekday = (date, locale) =>
  new Intl.DateTimeFormat(localeTag(locale), {
    weekday: 'short',
    day: '2-digit',
    month: '2-digit',
    timeZone: 'UTC',
  }).format(utcDate(date));

// Axis of the volume chart: the weekday in a 7-day period, the date otherwise.
export const axisDay = (date, locale, short) =>
  new Intl.DateTimeFormat(
    localeTag(locale),
    short
      ? { weekday: 'short', timeZone: 'UTC' }
      : { day: '2-digit', month: '2-digit', timeZone: 'UTC' }
  ).format(utcDate(date));

export const busiestDay = timeline =>
  timeline.reduce(
    (best, point) => (point.count > (best?.count || 0) ? point : best),
    null
  );

export const leadingChannel = channels => {
  const total = channels.reduce((sum, row) => sum + row.count, 0);
  const [top] = [...channels].sort((a, b) => b.count - a.count);
  return total && top.count ? { ...top, share: top.count / total } : null;
};
