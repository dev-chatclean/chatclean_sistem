module AccountSettingsSchema
  extend ActiveSupport::Concern

  CAPTAIN_MODEL_PROPERTIES = Llm::Models.model_feature_keys.index_with { { 'type': %w[string null] } }.freeze
  CAPTAIN_FEATURE_PROPERTIES = Llm::Models.feature_keys.index_with { { 'type': %w[boolean null] } }.freeze

  SETTINGS_PARAMS_SCHEMA = {
    'type': 'object',
    'properties':
      {
        'auto_resolve_after': { 'type': %w[integer null], 'minimum': 10, 'maximum': 1_439_856 },
        'auto_resolve_message': { 'type': %w[string null] },
        'auto_resolve_ignore_waiting': { 'type': %w[boolean null] },
        'audio_transcriptions': { 'type': %w[boolean null] },
        'auto_resolve_label': { 'type': %w[string null] },
        'enforce_mfa': { 'type': %w[boolean null] },
        'crm_auto_create_deals': { 'type': %w[boolean null] },
        'crm_lead_entry': {
          'type': %w[object null],
          'properties': {
            'inbox_ids': { 'type': 'array', 'items': { 'type': 'integer' } },
            'origins': { 'type': 'array', 'items': { 'type': 'string', 'enum': AccountCrm::LEAD_ORIGINS } },
            'sources': { 'type': 'array', 'items': { 'type': 'string', 'enum': AccountCrm::LEAD_SOURCES } },
            'alert_after_days': { 'type': %w[integer null], 'minimum': 1, 'maximum': 365 }
          },
          'additionalProperties': false
        },
        'crm_ai': {
          'type': %w[object null],
          'properties': {
            'next_step': { 'type': 'boolean' },
            'fill_on_move': { 'type': 'boolean' },
            'temperature': { 'type': 'boolean' },
            'monthly_cap': { 'type': 'number', 'minimum': 0 }
          },
          'additionalProperties': false
        },
        'keep_pending_on_bot_failure': { 'type': %w[boolean null] },
        'captain_auto_resolve_mode': { 'type': %w[string null], 'enum': ['evaluated', 'legacy', 'disabled', nil] },
        'conversation_required_attributes': {
          'type': %w[array null],
          'items': { 'type': 'string' }
        },
        'captain_models': {
          'type': %w[object null],
          'properties': CAPTAIN_MODEL_PROPERTIES,
          'additionalProperties': false
        },
        'captain_features': {
          'type': %w[object null],
          'properties': CAPTAIN_FEATURE_PROPERTIES,
          'additionalProperties': false
        }
      },
    'required': [],
    'additionalProperties': true
  }.to_json.freeze
end
