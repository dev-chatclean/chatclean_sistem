class Crm::StageImpulse < ApplicationRecord
  self.table_name = 'crm_stage_impulses'

  MAX_STEPS = 10

  belongs_to :account
  belongs_to :stage, class_name: 'Crm::Stage', inverse_of: :impulses
  has_many :steps, -> { order(:position, :id) }, class_name: 'Crm::StageImpulseStep', foreign_key: :impulse_id,
                                                 inverse_of: :impulse, dependent: :destroy

  accepts_nested_attributes_for :steps, allow_destroy: true

  scope :active, -> { where(active: true) }

  validates :name, presence: true, length: { maximum: 80 }
  validate :steps_count

  before_validation :inherit_account, on: :create
  before_validation :number_steps
  after_update_commit :cancel_scheduled_executions, if: -> { saved_change_to_active? && !active? }

  private

  def inherit_account
    self.account = stage&.account
  end

  def kept_steps
    steps.reject(&:marked_for_destruction?)
  end

  def cancel_scheduled_executions
    Crm::DealImpulseExecution.scheduled.where(step: steps).includes(:deal, step: :impulse).group_by(&:deal)
                             .each { |deal, executions| deal.cancel_impulse_executions(executions, 'impulse_disabled') }
  end

  def number_steps
    kept_steps.each_with_index { |step, index| step.position = index + 1 }
  end

  def steps_count
    return if kept_steps.size.between?(1, MAX_STEPS)

    errors.add(:base, I18n.t('crm.impulses.errors.steps_count', max: MAX_STEPS))
  end
end
