class Crm::AutoDealService
  pattr_initialize [:conversation!]

  # Only accounts with automatic deals pay for the account lock, which keeps two near-simultaneous
  # assignments (auto-assignment plus automation) from creating two deals.
  def perform
    return unless account.crm_auto_create_deals && conversation.assignee.present?

    account.with_lock { create_deal if new_lead? && matches_lead_entry? }
  end

  private

  delegate :account, :inbox, to: :conversation

  def create_deal
    account.crm_deals.create!(
      stage: account.crm_pipelines.find_by!(is_default: true).stages.initial.first!,
      contact: conversation.contact, assignee: conversation.assignee, conversation: conversation,
      lead_origin: lead_origin, lead_source: lead_source
    )
  end

  def new_lead?
    !account.crm_deals.open.exists?(contact_id: conversation.contact_id)
  end

  # A list with every option ticked (or no inbox picked) lets everything in, new channels included.
  # Conversations with no known origin (WhatsApp, e-mail...) are limited by the inbox list only.
  def matches_lead_entry?
    settings = account.crm_lead_entry_settings
    (settings['inbox_ids'].empty? || settings['inbox_ids'].include?(inbox.id)) &&
      (lead_origin.nil? || settings['origins'].sort == AccountCrm::LEAD_ORIGINS.sort || settings['origins'].include?(lead_origin)) &&
      (settings['sources'].sort == AccountCrm::LEAD_SOURCES.sort || settings['sources'].include?(lead_source))
  end

  def lead_origin
    @lead_origin ||= if inbox.instagram_direct? || conversation.additional_attributes['type'] == 'instagram_direct_message'
                       'instagram'
                     elsif inbox.facebook?
                       'facebook'
                     elsif inbox.web_widget?
                       'site'
                     end
  end

  def lead_source
    @lead_source ||= conversation.messages.incoming.exists?(["content_attributes ->> 'referral' IS NOT NULL"]) ? 'ad' : 'message'
  end
end
