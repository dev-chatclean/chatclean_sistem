class Crm::StageImpulseStep < ApplicationRecord
  self.table_name = 'crm_stage_impulse_steps'

  MESSAGE_TYPES = %w[text template].freeze
  MAX_DELAY_MINUTES = 90.days.in_minutes.to_i

  belongs_to :impulse, class_name: 'Crm::StageImpulse', inverse_of: :steps
  has_many :executions, class_name: 'Crm::DealImpulseExecution', foreign_key: :step_id, inverse_of: :step, dependent: :delete_all

  validates :message_type, inclusion: { in: MESSAGE_TYPES }
  validates :delay_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_DELAY_MINUTES }
  validates :content, presence: true, length: { maximum: 4096 }, if: :text?
  validate :template_chosen, unless: :text?

  def text?
    message_type == 'text'
  end

  private

  def template_chosen
    return if template_params['name'].present? && template_params['language'].present?

    errors.add(:base, I18n.t('crm.impulses.errors.template_required'))
  end
end
