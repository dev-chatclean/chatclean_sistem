import format from 'date-fns/format';
import fromUnixTime from 'date-fns/fromUnixTime';
import { channelLabel, originLabel, reasonLabel } from './salesReportLabels';

// "Baixar CSV": one section per visible block, in the order of the page, with plain numbers for spreadsheets.
const SECONDS_IN_DAY = 86400;
const PERCENT = 100;
const BYTE_ORDER_MARK = '\uFEFF';

const cell = value => {
  const text = value == null ? '' : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
};

const days = seconds =>
  seconds == null ? '' : (seconds / SECONDS_IN_DAY).toFixed(1);
const date = timestamp => format(fromUnixTime(timestamp), 'yyyy-MM-dd');
const inDays = (label, t) => t('CRM_REPORTS.SALES.CSV.DAYS', { label });

const SECTIONS = {
  indicators: (report, t) => {
    const { kpis } = report;
    const label = key => t(`CRM_REPORTS.SALES.KPIS.${key}.LABEL`);
    return [
      [t('CRM_REPORTS.SALES.CSV.INDICATOR'), t('CRM_REPORTS.SALES.CSV.VALUE')],
      [label('OPEN'), kpis.open_value],
      [t('CRM_REPORTS.SALES.STAGNATION.STALE'), kpis.stale_count],
      [label('WON'), kpis.won_value],
      [label('LOST'), kpis.lost_value],
      [
        label('CONVERSION'),
        kpis.conversion == null
          ? ''
          : `${Math.round(kpis.conversion * PERCENT)}%`,
      ],
      [label('TICKET'), kpis.average_ticket ?? ''],
      [inDays(label('CLOSE_TIME'), t), days(kpis.close_seconds)],
      [inDays(label('LOSS_TIME'), t), days(kpis.loss_seconds)],
    ];
  },
  pipeline: (report, t) => [
    [
      t('CRM_REPORTS.SALES.STAGNATION.STAGE'),
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.DEALS'),
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.VALUE'),
    ],
    ...report.stages.map(stage => [
      stage.name,
      stage.open_count,
      stage.open_value,
    ]),
  ],
  wins: (report, t) => [
    [t('CRM_REPORTS.SALES.WINS.DATE'), t('CRM_REPORTS.SALES.WINS.VALUE')],
    ...report.wins_timeline.map(point => [point.date, point.value]),
  ],
  conversion: (report, t) => [
    [
      t('CRM_REPORTS.SALES.CONVERSION.STAGE'),
      t('CRM_REPORTS.SALES.CONVERSION.REACHED'),
      t('CRM_REPORTS.SALES.CONVERSION.MOVED_ON'),
    ],
    ...report.stages.map(stage => [
      stage.name,
      stage.reached,
      stage.moved_on ?? '',
    ]),
  ],
  by_assignee: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.ASSIGNEE'),
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.DEALS'),
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.WON'),
      t('CRM_REPORTS.SALES.BY_ASSIGNEE.VALUE'),
    ],
    ...report.assignees.map(row => [
      row.name,
      row.deals,
      row.won_count,
      row.won_value,
    ]),
  ],
  by_origin: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_ORIGIN.ORIGIN'),
      t('CRM_REPORTS.SALES.SOURCES.LEADS'),
      t('CRM_REPORTS.SALES.SOURCES.WON'),
      t('CRM_REPORTS.SALES.SOURCES.LOST'),
      t('CRM_REPORTS.SALES.SOURCES.VALUE'),
    ],
    ...report.by_origin.map(row => [
      originLabel(row.key, t),
      row.leads,
      row.won,
      row.lost,
      row.value,
    ]),
  ],
  by_channel: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_CHANNEL.CHANNEL'),
      t('CRM_REPORTS.SALES.SOURCES.LEADS'),
      t('CRM_REPORTS.SALES.SOURCES.WON'),
      t('CRM_REPORTS.SALES.SOURCES.LOST'),
      t('CRM_REPORTS.SALES.SOURCES.VALUE'),
    ],
    ...report.by_channel.map(row => [
      channelLabel(row, t),
      row.leads,
      row.won,
      row.lost,
      row.value,
    ]),
  ],
  by_product: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_PRODUCT.PRODUCT'),
      t('CRM_REPORTS.SALES.BY_PRODUCT.UNITS'),
      t('CRM_REPORTS.SALES.BY_PRODUCT.REVENUE'),
    ],
    ...report.by_product.map(row => [row.name, row.units, row.revenue]),
  ],
  origin_wins: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_ORIGIN.ORIGIN'),
      t('CRM_REPORTS.SALES.SOURCES.VALUE'),
    ],
    ...report.origin_wins.map(row => [originLabel(row.key, t), row.value]),
  ],
  by_company: (report, t) => [
    [
      t('CRM_REPORTS.SALES.BY_COMPANY.COMPANY'),
      t('CRM_REPORTS.SALES.BY_COMPANY.WON'),
      t('CRM_REPORTS.SALES.BY_COMPANY.OPEN'),
    ],
    ...report.by_company.map(row => [row.name, row.won_value, row.open_value]),
  ],
  won_reasons: (report, t) => [
    [
      t('CRM_REPORTS.SALES.REASONS.REASON'),
      t('CRM_REPORTS.SALES.REASONS.DEALS'),
      t('CRM_REPORTS.SALES.REASONS.VALUE'),
    ],
    ...report.won_reasons.map(row => [
      reasonLabel(row.key, t),
      row.count,
      row.value,
    ]),
  ],
  lost_reasons: (report, t) => [
    [
      t('CRM_REPORTS.SALES.REASONS.REASON'),
      t('CRM_REPORTS.SALES.REASONS.DEALS'),
      t('CRM_REPORTS.SALES.REASONS.VALUE'),
    ],
    ...report.lost_reasons.map(row => [
      reasonLabel(row.key, t),
      row.count,
      row.value,
    ]),
  ],
  won_deals: (report, t) => [
    [
      t('CRM_REPORTS.SALES.DEALS.DEAL'),
      t('CRM_REPORTS.SALES.DEALS.ASSIGNEE'),
      t('CRM_REPORTS.SALES.DEALS.PRODUCTS'),
      t('CRM_REPORTS.SALES.DEALS.VALUE'),
      inDays(t('CRM_REPORTS.SALES.DEALS.CYCLE'), t),
      t('CRM_REPORTS.SALES.DEALS.CLOSED_AT'),
    ],
    ...report.won_deals.map(row => [
      `${t('CRM_DEALS.NUMBER', { number: row.number })} ${row.name}`,
      row.assignee,
      row.products.join(' | '),
      row.value,
      days(row.cycle_seconds),
      date(row.closed_at),
    ]),
  ],
  lost_deals: (report, t) => [
    [
      t('CRM_REPORTS.SALES.DEALS.DEAL'),
      t('CRM_REPORTS.SALES.DEALS.ASSIGNEE'),
      t('CRM_REPORTS.SALES.DEALS.STAGE'),
      t('CRM_REPORTS.SALES.DEALS.REASON'),
      t('CRM_REPORTS.SALES.DEALS.NOTE'),
      t('CRM_REPORTS.SALES.DEALS.VALUE'),
      t('CRM_REPORTS.SALES.DEALS.CLOSED_AT'),
    ],
    ...report.lost_deals.map(row => [
      `${t('CRM_DEALS.NUMBER', { number: row.number })} ${row.name}`,
      row.assignee,
      row.lost_stage,
      row.reason ? reasonLabel(row.reason, t) : '',
      row.note,
      row.value,
      date(row.closed_at),
    ]),
  ],
  lost_by_assignee: (report, t) => [
    [
      t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.ASSIGNEE'),
      t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.LOST'),
      t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.CLOSED'),
      t('CRM_REPORTS.SALES.LOST_BY_ASSIGNEE.VALUE'),
    ],
    ...report.assignees
      .filter(row => row.lost_count)
      .map(row => [
        row.name,
        row.lost_count,
        row.won_count + row.lost_count,
        row.lost_value,
      ]),
  ],
  where_lost: (report, t) => [
    [
      t('CRM_REPORTS.SALES.WHERE_LOST.STAGE'),
      t('CRM_REPORTS.SALES.WHERE_LOST.LOST'),
      t('CRM_REPORTS.SALES.WHERE_LOST.VALUE'),
    ],
    ...report.where_lost.map(row => [row.name, row.lost, row.value]),
  ],
  stagnation: (report, t) => [
    [
      t('CRM_REPORTS.SALES.STAGNATION.STAGE'),
      t('CRM_REPORTS.SALES.STAGNATION.OPEN'),
      t('CRM_REPORTS.SALES.STAGNATION.STALE'),
      inDays(t('CRM_REPORTS.SALES.STAGNATION.AVERAGE'), t),
    ],
    ...report.stages.map(stage => [
      stage.name,
      stage.open_count,
      stage.stale_count,
      days(stage.average_seconds),
    ]),
  ],
  collaborators: (report, t) => [
    [
      t('CRM_REPORTS.SALES.COLLABORATORS.ASSIGNEE'),
      t('CRM_REPORTS.SALES.COLLABORATORS.WON'),
      t('CRM_REPORTS.SALES.COLLABORATORS.WON_VALUE'),
      t('CRM_REPORTS.SALES.COLLABORATORS.LOST'),
      t('CRM_REPORTS.SALES.COLLABORATORS.LOST_VALUE'),
      t('CRM_REPORTS.SALES.COLLABORATORS.ACTIVITIES_DONE'),
      t('CRM_REPORTS.SALES.COLLABORATORS.OVERDUE'),
    ],
    ...report.assignees.map(row => [
      row.name,
      row.won_count,
      row.won_value,
      row.lost_count,
      row.lost_value,
      row.activities_done,
      row.activities_overdue,
    ]),
  ],
};

export const buildSalesReportCsv = (report, blockKeys, t) =>
  BYTE_ORDER_MARK +
  blockKeys
    .map(key =>
      [
        [t(`CRM_REPORTS.SALES.BLOCKS.NAMES.${key.toUpperCase()}`)],
        ...SECTIONS[key](report, t),
      ]
        .map(row => row.map(cell).join(','))
        .join('\n')
    )
    .join('\n\n');
