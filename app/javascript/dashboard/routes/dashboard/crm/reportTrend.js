// How a report number changed against the previous period, shared by the indicator cards.
const PERCENT = 100;

export const TREND_CLASSES = {
  better: 'text-n-teal-11',
  worse: 'text-n-ruby-11',
  same: 'text-n-slate-11',
};

// Null when there is nothing to compare with: nothing before and something now.
export const reportTrend = (
  current,
  previous,
  { lowerIsBetter = false } = {}
) => {
  if (!previous)
    return current ? null : { value: '0%', tone: 'same', up: true };
  const change = (current - previous) / previous;
  let tone = 'same';
  if (change !== 0) tone = change > 0 !== lowerIsBetter ? 'better' : 'worse';
  const sign = change > 0 ? '+' : '';
  return {
    value: `${sign}${Math.round(change * PERCENT)}%`,
    tone,
    up: change >= 0,
  };
};
