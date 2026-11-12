class Crm::DealImpulseExecution < ApplicationRecord
  self.table_name = 'crm_deal_impulse_executions'

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :impulse_executions
  belongs_to :step, class_name: 'Crm::StageImpulseStep', inverse_of: :executions
  belongs_to :message, optional: true

  enum :status, { scheduled: 0, sent: 1, canceled: 2, failed: 3 }

  delegate :impulse, to: :step

  # A reply from the contact stops the impulses set to stop on reply, in all of the contact's deals.
  def self.cancel_on_reply(contact)
    scheduled.joins(:deal, step: :impulse)
             .where(crm_deals: { contact_id: contact.id }, crm_stage_impulses: { stop_on_reply: true })
             .includes(:deal, step: :impulse)
             .group_by(&:deal)
             .each { |deal, executions| deal.cancel_impulse_executions(executions, 'contact_replied') }
  end

  def finish!(status, failure_reason: nil, message: nil)
    update!(status: status, failure_reason: failure_reason, message: message, executed_at: Time.current)
    deal.events.create!(account: account, event_type: "impulse_#{status}",
                        data: { 'impulse' => impulse.name, 'step' => step.position, 'reason' => failure_reason }.compact)
  end
end
