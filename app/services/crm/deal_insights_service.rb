# Temperature (cold, warm, hot) with a short reason and the suggested next step, from the deal and its conversation.
class Crm::DealInsightsService < Crm::DealAiService
  attr_reader :failure_reason

  def perform
    @failure_reason = blocking_reason
    return false if failure_reason

    answer = ask(feature: 'crm_deal_insights', instructions: instructions, schema: schema)
    unless answer
      @failure_reason = 'provider_error'
      return false
    end

    deal.update!(insight_attributes(answer).merge(ai_analyzed_at: Time.current))
  end

  private

  def features
    @features ||= account.crm_ai_insight_features
  end

  def blocking_reason
    return 'disabled' if account.crm_ai_settings.values_at(*AccountCrm::AI_INSIGHT_FEATURES).none?
    return 'cap_reached' if features.empty?

    'no_conversation' if conversation.nil? || chat_messages.empty?
  end

  def instructions
    parts = []
    if features.include?('temperature')
      parts << 'temperature: how likely the deal is to close soon (cold, warm or hot), judged by the engagement, tone and ' \
               'buying signals in the messages; temperature_reason: one short sentence (at most 200 characters) with the reason.'
    end
    parts << 'next_step: the one practical action the salesperson should take next, in one or two sentences.' if features.include?('next_step')
    "Return #{parts.join(' ')}"
  end

  def schema
    properties = {}
    if features.include?('temperature')
      properties['temperature'] = { type: 'string', enum: Crm::Deal.ai_temperatures.keys }
      properties['temperature_reason'] = { type: 'string' }
    end
    properties['next_step'] = { type: 'string' } if features.include?('next_step')
    { type: 'object', properties: properties, required: properties.keys, additionalProperties: false }
  end

  def insight_attributes(answer)
    attributes = {}
    if features.include?('temperature')
      attributes[:ai_temperature] = answer['temperature']
      attributes[:ai_temperature_reason] = answer['temperature_reason'].to_s.truncate(280)
    end
    attributes[:ai_next_step] = answer['next_step'] if features.include?('next_step')
    attributes
  end

  def event_name
    'crm_deal_insights'
  end
end
