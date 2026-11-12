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
  'billing',
  'attachments',
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
