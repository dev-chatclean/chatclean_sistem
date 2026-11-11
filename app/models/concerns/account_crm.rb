module AccountCrm
  extend ActiveSupport::Concern

  LEAD_ORIGINS = %w[catalog facebook ad_form instagram site].freeze
  LEAD_SOURCES = %w[message ad form].freeze
  AI_FEATURES = %w[next_step fill_on_move temperature].freeze

  included do
    has_many :crm_pipelines, class_name: 'Crm::Pipeline', dependent: :destroy_async
    has_many :crm_deals, class_name: 'Crm::Deal', dependent: :destroy_async
    has_many :crm_products, class_name: 'Crm::Product', dependent: :delete_all
    store_accessor :settings, :crm_auto_create_deals, :crm_lead_entry, :crm_ai
    validate :validate_crm_auto_create_deals, if: -> { crm_auto_create_deals && will_save_change_to_settings? }
    validate :validate_crm_ai_monthly_cap, if: -> { crm_ai.present? && will_save_change_to_settings? }
  end

  def crm_lead_entry_settings
    { 'inbox_ids' => [], 'origins' => LEAD_ORIGINS, 'sources' => LEAD_SOURCES, 'alert_after_days' => nil }.merge(crm_lead_entry.to_h)
  end

  def crm_ai_settings
    AI_FEATURES.index_with(false).merge('monthly_cap' => 0).merge(crm_ai.to_h)
  end

  private

  def validate_crm_auto_create_deals
    return if crm_pipelines.exists?(is_default: true)

    errors.add(:base, I18n.t('crm.settings.errors.auto_create_requires_default_pipeline'))
  end

  def validate_crm_ai_monthly_cap
    return unless crm_ai_settings.values_at(*AI_FEATURES).any?
    return if crm_ai_settings['monthly_cap'].to_d.positive?

    errors.add(:base, I18n.t('crm.settings.errors.ai_requires_monthly_cap'))
  end
end
