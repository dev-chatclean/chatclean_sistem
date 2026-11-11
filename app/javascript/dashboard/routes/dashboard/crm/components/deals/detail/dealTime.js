const SECONDS_IN_MINUTE = 60;
const SECONDS_IN_HOUR = 3600;
const SECONDS_IN_DAY = 86400;

export const formatDateTime = (timestamp, locale) =>
  new Intl.DateTimeFormat(locale.replace('_', '-'), {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(timestamp * 1000));

export const formatShortDateTime = (timestamp, locale) =>
  new Intl.DateTimeFormat(locale.replace('_', '-'), {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(timestamp * 1000));

export const formatDuration = (seconds, t) => {
  if (seconds < SECONDS_IN_MINUTE)
    return t('CRM_DEALS.DETAIL.DURATION.LESS_THAN_MINUTE');
  if (seconds < SECONDS_IN_HOUR) {
    return t('CRM_DEALS.DETAIL.DURATION.MINUTES', {
      n: Math.floor(seconds / SECONDS_IN_MINUTE),
    });
  }
  if (seconds < SECONDS_IN_DAY) {
    return t('CRM_DEALS.DETAIL.DURATION.HOURS', {
      n: Math.floor(seconds / SECONDS_IN_HOUR),
    });
  }
  return t('CRM_DEALS.DETAIL.DURATION.DAYS', {
    n: Math.floor(seconds / SECONDS_IN_DAY),
  });
};

export const entryDuration = entry =>
  (entry.left_at || Math.floor(Date.now() / 1000)) - entry.entered_at;
