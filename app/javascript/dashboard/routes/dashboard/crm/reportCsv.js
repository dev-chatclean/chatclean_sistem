// CSV of a CRM report: one section per block, each a title line followed by its rows, with a byte order mark for Excel.
const BYTE_ORDER_MARK = '﻿';

const cell = value => {
  const text = value == null ? '' : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};

export const toCsv = sections =>
  BYTE_ORDER_MARK +
  sections
    .map(({ title, rows }) =>
      [[title], ...rows].map(row => row.map(cell).join(',')).join('\n')
    )
    .join('\n\n');
