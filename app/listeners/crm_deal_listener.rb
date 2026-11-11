class CrmDealListener < BaseListener
  include Singleton

  def assignee_changed(event)
    conversation, _account = extract_conversation_and_account(event)
    Crm::AutoDealService.new(conversation: conversation).perform
  end

  # An archived contact who writes again comes back to the contact list.
  def message_created(event)
    message = event.data[:message]
    return unless message.incoming? && message.sender.is_a?(Contact) && message.sender.archived_at

    message.sender.update!(archived_at: nil)
  end
end
