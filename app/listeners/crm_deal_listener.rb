class CrmDealListener < BaseListener
  include Singleton

  def assignee_changed(event)
    conversation, _account = extract_conversation_and_account(event)
    Crm::AutoDealService.new(conversation: conversation).perform
  end
end
