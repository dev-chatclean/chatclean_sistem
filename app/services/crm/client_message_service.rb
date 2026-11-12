# Sends a message to the deal's contact, in the deal's conversation or in the contact's latest one.
# Text needs the channel's reply window open; a template needs a WhatsApp conversation and an approved template.
class Crm::ClientMessageService
  WHATSAPP = 'Channel::Whatsapp'.freeze
  VARIABLE_PATTERN = /{{\s*((?:deal|activity)\.\w+)\s*}}/

  pattr_initialize [:deal!, :message_type!, :content, :template_params, { variables: {} }]

  attr_reader :failure_reason

  def perform
    @failure_reason = blocking_reason
    return if failure_reason

    Messages::MessageBuilder.new(nil, conversation, message_params).perform
  end

  private

  def template?
    message_type == 'template'
  end

  def blocking_reason
    return 'no_contact' if deal.contact.nil?
    return template? ? 'no_whatsapp_conversation' : 'no_conversation' if conversation.nil?
    return template.nil? ? 'template_not_found' : nil if template?

    'outside_window' unless conversation.can_reply?
  end

  def conversation
    @conversation ||= template? ? whatsapp_conversation : deal.conversation || contact_conversations.first
  end

  def whatsapp_conversation
    return deal.conversation if deal.conversation&.inbox&.channel_type == WHATSAPP

    contact_conversations.joins(:inbox).find_by(inboxes: { channel_type: WHATSAPP })
  end

  def contact_conversations
    deal.contact.conversations.order(last_activity_at: :desc)
  end

  def template
    @template ||= conversation.inbox.channel.message_templates.find do |item|
      item['name'] == template_params['name'] && item['language'] == template_params['language'] && item['status']&.downcase == 'approved'
    end
  end

  def message_params
    return { content: render(content) } unless template?

    body = template['components'].find { |component| component['type'] == 'BODY' }
    params = template_params.deep_dup
    params['processed_params'] = (params['processed_params'] || {}).deep_transform_values { |value| render(value) }
    { content: body['text'], template_params: params.merge('content_mode' => 'raw_template') }
  end

  # Contact, agent and conversation variables are rendered by Chatwoot when the message is created.
  def render(text)
    values = deal_variables.merge(variables)
    text.to_s.gsub(VARIABLE_PATTERN) { values.fetch(Regexp.last_match(1), '') }
  end

  def deal_variables
    { 'deal.title' => deal.display_name, 'deal.stage' => deal.stage.name, 'deal.owner' => deal.assignee.name }
  end
end
