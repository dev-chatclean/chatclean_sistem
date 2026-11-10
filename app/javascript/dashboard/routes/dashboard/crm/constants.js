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
