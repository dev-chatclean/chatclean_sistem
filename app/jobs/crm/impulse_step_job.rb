class Crm::ImpulseStepJob < ApplicationJob
  queue_as :medium

  def perform(execution_id)
    execution = Crm::DealImpulseExecution.find_by(id: execution_id)
    return unless execution&.scheduled?

    deal = execution.deal
    return execution.finish!(:canceled, failure_reason: 'stage_changed') if deal.stage_id != execution.impulse.stage_id

    step = execution.step
    sender = Crm::ClientMessageService.new(deal: deal, message_type: step.message_type, content: step.content,
                                           template_params: step.template_params)
    message = sender.perform
    message ? execution.finish!(:sent, message: message) : execution.finish!(:failed, failure_reason: sender.failure_reason)
  end
end
