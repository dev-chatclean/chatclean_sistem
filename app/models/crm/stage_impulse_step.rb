class Crm::StageImpulseStep < ApplicationRecord
  include CrmClientMessageFields

  self.table_name = 'crm_stage_impulse_steps'

  MAX_DELAY_MINUTES = 90.days.in_minutes.to_i

  belongs_to :impulse, class_name: 'Crm::StageImpulse', inverse_of: :steps
  has_many :executions, class_name: 'Crm::DealImpulseExecution', foreign_key: :step_id, inverse_of: :step, dependent: :delete_all

  validates :delay_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_DELAY_MINUTES }
end
