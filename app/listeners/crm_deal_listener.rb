class CrmDealListener < BaseListener
  include Singleton

  AI_INSIGHTS_DELAY = 10.minutes

  def assignee_changed(event)
    conversation, _account = extract_conversation_and_account(event)
    Crm::AutoDealService.new(conversation: conversation).perform
  end

  # A contact who writes again comes back from the archive and stops the impulses set to stop on reply.
  def message_created(event)
    message = event.data[:message]
    return unless message.incoming? && message.sender.is_a?(Contact)

    message.sender.update!(archived_at: nil) if message.sender.archived_at
    Crm::DealImpulseExecution.cancel_on_reply(message.sender)
    schedule_ai_insights(message)
  end

  private

  # Temperature and next step wait 10 minutes for the contact to stop writing.
  def schedule_ai_insights(message)
    return if message.account.crm_ai_insight_features.empty?

    message.account.crm_deals.open.where(contact: message.sender).pluck(:id).each do |deal_id|
      Crm::DealInsightsJob.set(wait: AI_INSIGHTS_DELAY).perform_later(deal_id, message.id)
    end
  end
end
