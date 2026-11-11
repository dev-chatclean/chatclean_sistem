import { DAY_IN_SECONDS, STALE_WARNING_RATIO } from './constants';

const currencyFormatter = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

export const formatCurrency = value => currencyFormatter.format(value || 0);

export const daysInStage = deal =>
  Math.max(
    0,
    Math.floor((Date.now() / 1000 - deal.stage_entered_at) / DAY_IN_SECONDS)
  );

export const staleLevel = (deal, stage) => {
  if (deal.status !== 'open' || !stage?.stale_after_days) return '';
  const days = daysInStage(deal);
  if (days > stage.stale_after_days) return 'danger';
  if (days >= stage.stale_after_days * STALE_WARNING_RATIO) return 'warning';
  return '';
};

export const isClosingStage = stage =>
  ['won', 'lost'].includes(stage?.stage_type);
