import { toCsv } from './reportCsv';
import {
  busiestDay,
  channelKindLabel,
  leadingChannel,
} from './overviewReportLabels';

// "Baixar CSV" of the Visão geral: indicators, highlights and the 4 blocks, with plain numbers.
const PERCENT = 100;
const ratio = value => (value == null ? '' : `${Math.round(value * PERCENT)}%`);

export const buildOverviewReportCsv = (report, t) => {
  const { kpis } = report;
  const channel = leadingChannel(report.by_channel);
  const day = busiestDay(report.volume_timeline);
  const label = key => t(`CRM_REPORTS.OVERVIEW.KPIS.${key}.LABEL`);
  const header = [
    t('CRM_REPORTS.SALES.CSV.INDICATOR'),
    t('CRM_REPORTS.SALES.CSV.VALUE'),
  ];
  return toCsv([
    {
      title: t('CRM_REPORTS.SALES.BLOCKS.NAMES.INDICATORS'),
      rows: [
        header,
        [label('CONVERSATIONS'), kpis.conversations],
        [label('OPEN'), kpis.open_count],
        [t('CRM_REPORTS.OVERVIEW.CSV.WAITING'), kpis.waiting_count],
        [label('WON'), kpis.won_value],
        [t('CRM_REPORTS.OVERVIEW.CSV.WON_COUNT'), kpis.won_count],
        [label('CONVERSION'), ratio(kpis.conversion)],
      ],
    },
    {
      title: t('CRM_REPORTS.OVERVIEW.CSV.HIGHLIGHTS'),
      rows: [
        header,
        [
          t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.TOP_CHANNEL.LABEL'),
          channel ? channelKindLabel(channel.key, t) : '',
        ],
        [t('CRM_REPORTS.OVERVIEW.HIGHLIGHTS.BEST_DAY.LABEL'), day?.date || ''],
      ],
    },
    {
      title: t('CRM_REPORTS.OVERVIEW.VOLUME.TITLE'),
      rows: [
        [
          t('CRM_REPORTS.OVERVIEW.VOLUME.DATE'),
          t('CRM_REPORTS.OVERVIEW.VOLUME.COUNT'),
        ],
        ...report.volume_timeline.map(point => [point.date, point.count]),
      ],
    },
    {
      title: t('CRM_REPORTS.OVERVIEW.BY_CHANNEL.TITLE'),
      rows: [
        [
          t('CRM_REPORTS.OVERVIEW.BY_CHANNEL.CHANNEL'),
          t('CRM_REPORTS.OVERVIEW.VOLUME.COUNT'),
        ],
        ...report.by_channel.map(row => [
          channelKindLabel(row.key, t),
          row.count,
        ]),
      ],
    },
    {
      title: t('CRM_REPORTS.OVERVIEW.PIPELINE.TITLE'),
      rows: [
        [
          t('CRM_REPORTS.SALES.STAGNATION.STAGE'),
          t('CRM_REPORTS.SALES.BY_ASSIGNEE.DEALS'),
          t('CRM_REPORTS.SALES.BY_ASSIGNEE.VALUE'),
        ],
        ...(report.pipeline?.stages || []).map(stage => [
          stage.name,
          stage.open_count,
          stage.open_value,
        ]),
      ],
    },
    {
      title: t('CRM_REPORTS.OVERVIEW.AGENTS.TITLE'),
      rows: [
        [
          t('CRM_REPORTS.OVERVIEW.AGENTS.AGENT'),
          t('CRM_REPORTS.OVERVIEW.AGENTS.CONVERSATIONS'),
          t('CRM_REPORTS.OVERVIEW.AGENTS.WON_VALUE'),
        ],
        ...report.agents.map(agent => [
          agent.name,
          agent.conversations,
          agent.won_value,
        ]),
      ],
    },
  ]);
};
