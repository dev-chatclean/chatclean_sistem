class CrmDealListener < BaseListener
  include Singleton

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
  end
end
