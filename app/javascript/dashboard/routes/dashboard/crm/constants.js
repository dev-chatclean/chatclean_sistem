export const PIPELINE_NAME_MAX_LENGTH = 100;
export const STAGE_NAME_MIN_LENGTH = 2;
export const STAGE_NAME_MAX_LENGTH = 50;

export const STAGE_COLORS = [
  '#1F93FF',
  '#8B5CF6',
  '#D97706',
  '#0D9488',
  '#44CE4B',
  '#E0484E',
  '#EA580C',
  '#64748B',
];

export const DEFAULT_WON_COLOR = '#44CE4B';
export const DEFAULT_LOST_COLOR = '#E0484E';

export const CLOSING_STAGE_TYPES = ['won', 'lost'];

export const PIPELINE_TYPES = ['sales', 'management'];
export const ITEM_LABELS = ['deal', 'client', 'case', 'process', 'custom'];
export const ITEM_LABEL_CUSTOM_MAX_LENGTH = 30;
export const PIPELINE_DESCRIPTION_MAX_LENGTH = 500;
export const PIPELINE_GROUP_MAX_LENGTH = 60;
export const DEFAULT_STALE_AFTER_DAYS = 7;
export const MAX_STALE_DAYS = 365;

export const CARD_FIELDS = [
  'expected_close_date',
  'products',
  'next_task',
  'contact_labels',
  'origin',
  'attachments',
  'temperature',
];
export const MAX_CARD_FIELDS = 4;

export const LEAD_ORIGINS = [
  'catalog',
  'facebook',
  'ad_form',
  'instagram',
  'site',
];
export const LEAD_SOURCES = ['message', 'ad', 'form'];

export const AI_FEATURES = ['next_step', 'fill_on_move', 'temperature'];
export const AI_TEMPERATURE_STYLES = {
  cold: { icon: 'i-lucide-snowflake', classes: 'bg-n-blue-3 text-n-blue-11' },
  warm: { icon: 'i-lucide-sun', classes: 'bg-n-amber-3 text-n-amber-11' },
  hot: { icon: 'i-lucide-flame', classes: 'bg-n-ruby-3 text-n-ruby-11' },
};

export const SETTINGS_TABS = ['pipeline', 'lead_entry', 'card'];

export const UI_SETTINGS_KEYS = {
  PANEL_COLLAPSED: 'crm_pipelines_panel_collapsed',
  LEAD_ENTRY_HINT_DISMISSED: 'crm_lead_entry_hint_dismissed',
};

export const MAX_REQUIRED_TASKS = 20;
export const TASK_TITLE_MAX_LENGTH = 120;
export const STAGE_DEAL_REQUIREMENTS = [
  'require_expected_close_date',
  'require_positive_value',
  'require_product',
];

export const WIN_REASONS = [
  'not_informed',
  'best_price',
  'delivery_time',
  'relationship',
  'referral',
  'product_features',
  'other',
];
export const LOSS_REASONS = [
  'price',
  'no_interest',
  'competitor',
  'no_response',
  'out_of_profile',
  'other',
];
export const STALE_WARNING_RATIO = 0.75;
export const DAY_IN_SECONDS = 86400;
export const SEARCH_DEBOUNCE_MS = 300;

export const BOARD_SORTS = [
  'longest_in_stage',
  'recently_moved',
  'recently_created',
  'oldest_created',
  'highest_value',
  'lowest_value',
  'next_activity',
];
export const OPEN_PERIODS = ['any', 7, 30, 90];
export const CLOSED_PERIODS = [7, 30, 90];
export const DEFAULT_CLOSED_PERIOD = 30;
export const SERVER_CLOSED_WINDOW_DAYS = 30;

export const BOARD_FILTER_FIELDS = [
  { key: 'assignee', icon: 'i-lucide-user', type: 'assignee' },
  { key: 'label', icon: 'i-lucide-tag', type: 'label' },
  { key: 'product', icon: 'i-lucide-package', type: 'product' },
  { key: 'status', icon: 'i-lucide-flag', type: 'status' },
  { key: 'loss_reason', icon: 'i-lucide-circle-x', type: 'loss_reason' },
  { key: 'lead_origin', icon: 'i-lucide-radar', type: 'lead_origin' },
  { key: 'stage', icon: 'i-lucide-columns-3', type: 'stage' },
  { key: 'value', icon: 'i-lucide-banknote', type: 'range' },
  { key: 'activities', icon: 'i-lucide-calendar-clock', type: 'activity' },
  { key: 'stale', icon: 'i-lucide-hourglass', type: 'flag' },
  { key: 'contact', icon: 'i-lucide-contact', type: 'text' },
  { key: 'company', icon: 'i-lucide-building-2', type: 'text' },
  { key: 'title', icon: 'i-lucide-type', type: 'text' },
  { key: 'channel', icon: 'i-lucide-inbox', type: 'inbox' },
  { key: 'created_at', icon: 'i-lucide-calendar-plus', type: 'date' },
  { key: 'stage_entered_at', icon: 'i-lucide-log-in', type: 'date' },
  { key: 'expected_close_date', icon: 'i-lucide-calendar-check', type: 'date' },
];

export const SALES_REPORT_PERIODS = [7, 30, 90];
export const SALES_REPORT_DEFAULT_PERIOD = 30;
export const SALES_REPORT_WEEKLY_PERIOD = 90;
export const SALES_REPORT_DEALS_LIMIT = 100;
export const SALES_REPORT_UI_KEY = 'crm_sales_report_blocks';
// The blocks of the report in the order of the mensagem.dev report; wide blocks take the whole row.
export const SALES_REPORT_BLOCKS = [
  { key: 'indicators', wide: true },
  { key: 'pipeline' },
  { key: 'wins' },
  { key: 'conversion', wide: true, needsStages: true },
  { key: 'by_assignee' },
  { key: 'by_origin' },
  { key: 'by_channel', wide: true },
  { key: 'by_product' },
  { key: 'origin_wins' },
  { key: 'by_company', wide: true },
  { key: 'won_reasons', wide: true },
  { key: 'won_deals', wide: true },
  { key: 'lost_reasons', wide: true },
  { key: 'lost_by_assignee', wide: true },
  { key: 'where_lost', wide: true, needsStages: true },
  { key: 'lost_deals', wide: true },
  { key: 'stagnation', wide: true, needsStages: true },
  { key: 'collaborators', wide: true },
];
export const OVERVIEW_REPORT_DEFAULT_PERIOD = 7;
export const CONVERSATION_STATUSES = ['open', 'pending', 'snoozed', 'resolved'];
export const CONTACT_TYPES = ['visitor', 'lead', 'customer'];
// "Filtrar" of the Visão geral report. "Atendimento por IA" waits for the AI attendant (E6).
export const OVERVIEW_REPORT_FILTER_FIELDS = [
  { key: 'team', icon: 'i-lucide-users', type: 'team' },
  { key: 'channel', icon: 'i-lucide-inbox', type: 'inbox' },
  { key: 'assignee', icon: 'i-lucide-user', type: 'assignee' },
  {
    key: 'conversation_status',
    icon: 'i-lucide-flag',
    type: 'choice',
    choices: CONVERSATION_STATUSES,
    choiceLabel: 'CRM_REPORTS.OVERVIEW.CONVERSATION_STATUS',
  },
  { key: 'contact_label', icon: 'i-lucide-tag', type: 'label' },
  {
    key: 'contact_type',
    icon: 'i-lucide-contact',
    type: 'choice',
    choices: CONTACT_TYPES,
    choiceLabel: 'CRM_REPORTS.OVERVIEW.CONTACT_TYPE',
  },
  {
    key: 'unread',
    icon: 'i-lucide-mail-warning',
    type: 'flag',
    hint: 'CRM_REPORTS.OVERVIEW.UNREAD_HINT',
  },
  { key: 'created_at', icon: 'i-lucide-calendar-plus', type: 'date' },
  { key: 'last_activity_at', icon: 'i-lucide-message-square', type: 'date' },
];
export const SALES_REPORT_FILTER_FIELDS = [
  { key: 'pipeline', icon: 'i-lucide-funnel', type: 'pipeline' },
  { key: 'stage', icon: 'i-lucide-columns-3', type: 'stage' },
  { key: 'assignee', icon: 'i-lucide-user', type: 'assignee' },
  { key: 'value', icon: 'i-lucide-banknote', type: 'range' },
  { key: 'contact', icon: 'i-lucide-contact', type: 'text' },
  { key: 'company', icon: 'i-lucide-building-2', type: 'text' },
  { key: 'title', icon: 'i-lucide-type', type: 'text' },
  { key: 'channel', icon: 'i-lucide-inbox', type: 'inbox' },
  { key: 'closed_at', icon: 'i-lucide-calendar-check-2', type: 'date' },
  { key: 'created_at', icon: 'i-lucide-calendar-plus', type: 'date' },
  { key: 'stage_entered_at', icon: 'i-lucide-log-in', type: 'date' },
];

export const ACTIVITY_TYPES = [
  { value: 'call', icon: 'i-lucide-phone' },
  { value: 'follow_up', icon: 'i-lucide-reply' },
  { value: 'meeting', icon: 'i-lucide-calendar-days' },
  { value: 'internal', icon: 'i-lucide-clipboard-list' },
];
export const ACTIVITY_PRIORITIES = ['low', 'medium', 'high'];
export const ACTIVITY_RECURRENCES = ['never', 'daily', 'weekly', 'monthly'];
export const REMIND_BEFORE_OPTIONS = [null, 0, 5, 10, 15, 30, 60, 1440];
export const DEFAULT_REMIND_BEFORE_MINUTES = 10;
export const DEFAULT_ACTIVITY_HOUR = 9;
export const ACTIVITY_TITLE_MAX_LENGTH = 120;
export const MAX_ACTIVITY_DURATION_MINUTES = 1440;
export const MAX_CHECKLIST_ITEMS = 30;
export const ACTIVITY_FILTERS = ['overdue', 'today', 'upcoming', 'none'];

export const PRODUCT_NAME_MAX_LENGTH = 120;
export const PRODUCT_SKU_MAX_LENGTH = 60;
export const MAX_PRODUCT_QUANTITY = 100000;

export const DEAL_FILE_CATEGORIES = [
  'proposal',
  'contract',
  'client_document',
  'receipt',
  'other',
];
export const DEAL_FILE_ACCEPT =
  '.pdf,.txt,.csv,.zip,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.png,.jpg,.jpeg,.webp';

export const IMPULSE_MAX_STEPS = 10;
export const IMPULSE_NAME_MAX_LENGTH = 80;
export const IMPULSE_MAX_DELAY_MINUTES = 90 * 24 * 60;
export const IMPULSE_DELAY_UNITS = { MINUTES: 1, HOURS: 60, DAYS: 24 * 60 };
export const IMPULSE_VARIABLES = [
  '{{contact.name}}',
  '{{contact.first_name}}',
  '{{deal.title}}',
  '{{deal.stage}}',
  '{{deal.owner}}',
];

export const CAMPAIGN_NAME_MAX_LENGTH = 80;
export const CAMPAIGN_MAX_STALE_DAYS = 365;
export const CAMPAIGN_POLL_INTERVAL_MS = 5000;
export const CAMPAIGN_PREVIEW_DEBOUNCE_MS = 400;
export const CAMPAIGN_COUNT_STATUSES = [
  'scheduled',
  'sent',
  'failed',
  'canceled',
];

export const CLIENT_REMINDER_OPTIONS = [15, 30, 60, 1440];
export const CLIENT_REMINDER_VARIABLES = [
  '{{contact.first_name}}',
  '{{contact.name}}',
  '{{activity.title}}',
  '{{activity.date}}',
  '{{activity.time}}',
  '{{deal.title}}',
  '{{deal.owner}}',
];
