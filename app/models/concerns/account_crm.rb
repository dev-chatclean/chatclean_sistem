module AccountCrm
  extend ActiveSupport::Concern

  included do
    has_many :crm_pipelines, class_name: 'Crm::Pipeline', dependent: :destroy_async
    store_accessor :settings, :crm_auto_create_deals
    validate :validate_crm_auto_create_deals, if: -> { crm_auto_create_deals && will_save_change_to_settings? }
  end

  private

  def validate_crm_auto_create_deals
    return if crm_pipelines.exists?(is_default: true)

    errors.add(:base, I18n.t('crm.settings.errors.auto_create_requires_default_pipeline'))
  end
end
