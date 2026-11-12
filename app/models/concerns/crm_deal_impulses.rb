# The impulses of a stage are scheduled when a deal enters it, and canceled when it leaves.
module CrmDealImpulses
  extend ActiveSupport::Concern

  included do
    has_many :impulse_executions, -> { order(:scheduled_at, :id) }, class_name: 'Crm::DealImpulseExecution', inverse_of: :deal,
                                                                    dependent: :delete_all
    after_commit :restart_impulses, on: [:create, :update], if: :saved_change_to_stage_id?
  end

  def cancel_impulse_executions(executions, reason)
    executions.group_by(&:impulse).each do |impulse, items|
      items.each { |execution| execution.update!(status: :canceled, failure_reason: reason, executed_at: Time.current) }
      events.create!(account: account, event_type: 'impulse_canceled',
                     data: { 'impulse' => impulse.name, 'steps' => items.size, 'reason' => reason })
    end
  end

  private

  def restart_impulses
    cancel_impulse_executions(impulse_executions.scheduled.includes(step: :impulse).to_a, 'stage_changed')
    impulses = stage.impulses.active.includes(:steps).to_a
    return if impulses.empty?
    return record_impulse_failure(impulses, 'no_contact') if contact.nil?

    impulses.each { |impulse| schedule_impulse(impulse) }
  end

  # Each step waits its delay after the previous one.
  def schedule_impulse(impulse)
    run_at = Time.current
    impulse.steps.each do |step|
      run_at += step.delay_minutes.minutes
      execution = impulse_executions.create!(account: account, step: step, scheduled_at: run_at)
      Crm::ImpulseStepJob.set(wait_until: run_at).perform_later(execution.id)
    end
  end

  def record_impulse_failure(impulses, reason)
    events.create!(account: account, event_type: 'impulse_failed', data: { 'impulse' => impulses.map(&:name).to_sentence, 'reason' => reason })
  end
end
