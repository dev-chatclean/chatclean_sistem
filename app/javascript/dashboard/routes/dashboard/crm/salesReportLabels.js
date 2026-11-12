// Names shown for the origin and channel rows of the sales report, on the page and in the CSV.
export const originLabel = (key, t) =>
  key
    ? t(`CRM_PIPELINES.LEAD_ENTRY.OPTIONS.${key.toUpperCase()}`)
    : t('CRM_REPORTS.SALES.BY_ORIGIN.NONE');

export const channelLabel = (row, t) =>
  row.name || t('CRM_REPORTS.SALES.BY_CHANNEL.NONE');

export const reasonLabel = (key, t) =>
  t(`CRM_DEALS.REASONS.${key.toUpperCase()}`);
