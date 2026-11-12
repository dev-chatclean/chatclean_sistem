# Base of the pipeline AI calls (Captain::BaseTaskService, MIT edition): the deal and its conversation as context, the
# ChatClean key from the Super Admin (never the account's OpenAI hook) and the account's monthly spend instead of Captain's quota.
class Crm::DealAiService < Captain::BaseTaskService
  MESSAGES_LIMIT = 40
  EVENTS_LIMIT = 10

  pattr_initialize [:deal!]

  delegate :account, to: :deal

  private

  # The deal's conversation, or the contact's latest one.
  def conversation
    @conversation ||= deal.conversation || deal.contact&.conversations&.order(last_activity_at: :desc)&.first
  end

  def chat_messages
    @chat_messages ||= conversation.messages.where(message_type: [:incoming, :outgoing], private: false)
                                   .reorder(id: :desc).limit(MESSAGES_LIMIT).to_a.reverse
                                   .filter_map { |message| chat_line(message) }
  end

  def chat_line(message)
    content = message.content_for_llm
    "#{message.incoming? ? 'Cliente' : 'Atendente'}: #{content}" if content.present?
  end

  def counts_toward_usage?
    false
  end

  def ask(feature:, instructions:, schema:)
    result = make_api_call(feature: feature, schema: schema,
                           messages: [{ role: 'system', content: system_prompt(instructions) }, { role: 'user', content: context }])
    if result[:error]
      Rails.logger.warn("[CRM AI] #{event_name} deal=#{deal.id}: #{result[:error]}")
      return
    end

    record_usage(feature, result[:usage])
    result[:message]
  end

  def system_prompt(instructions)
    <<~PROMPT
      You help a sales team that works in a CRM pipeline. You get one deal and the latest messages of its conversation.
      Use only what the deal data and the messages say; never invent facts. Today is #{Time.zone.today}.
      #{instructions}
      Write every text in #{account.locale_english_name}.
    PROMPT
  end

  def context
    [deal_text, "Conversa:\n#{chat_messages.join("\n")}"].join("\n\n")
  end

  def deal_text
    (deal_lines + activity_lines + event_lines).join("\n")
  end

  def deal_lines
    {
      'Negócio' => deal.display_name, 'Pipeline' => deal.pipeline.name, 'Etapa' => deal.stage.name,
      'Na etapa desde' => deal.stage_entered_at.to_date, 'Valor' => "R$ #{deal.value}", 'Responsável' => deal.assignee.name,
      'Previsão de fechamento' => deal.expected_close_date, 'Campos' => deal.custom_attributes.presence&.to_json
    }.compact.map { |label, value| "#{label}: #{value}" }
  end

  def activity_lines
    deal.pending_activities.limit(5).map { |activity| "Atividade pendente: #{activity.title} (#{activity.due_at.to_date})" }
  end

  def event_lines
    deal.events.reorder(created_at: :desc).limit(EVENTS_LIMIT).reverse.map do |event|
      "Histórico: #{event.created_at.to_date} #{event.event_type} #{event.data.slice('to_stage_name', 'field', 'to').to_json}"
    end
  end

  def record_usage(feature, usage)
    Crm::AiUsage.record!(account: account, model: resolved_model(model: nil, feature: feature),
                         input_tokens: usage['prompt_tokens'].to_i, output_tokens: usage['completion_tokens'].to_i)
  end
end
