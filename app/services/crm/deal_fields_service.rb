# "Preencher campos ao mover": before a stage change is saved, fills the empty fields the new stage requires with what
# the conversation says. Values that do not fit the field type are dropped; the stage check then reports what is still missing.
class Crm::DealFieldsService < Crm::DealAiService
  TIMEOUT = 8.seconds

  def perform
    return unless account.crm_ai_active_features.include?('fill_on_move')

    @definitions = deal.missing_custom_field_definitions
    return if @definitions.empty? || conversation.nil? || chat_messages.empty?

    answer = Timeout.timeout(TIMEOUT) { ask(feature: 'crm_deal_fields', instructions: instructions, schema: schema) }
    fill(answer) if answer
  rescue Timeout::Error
    Rails.logger.warn("[CRM AI] #{event_name} deal=#{deal.id}: timed out")
  end

  private

  def fill(answer)
    values = @definitions.each_with_object({}) do |definition, found|
      value = answer[definition.attribute_key]
      found[definition.attribute_key] = value if (value.present? || value == false) && deal.valid_custom_value?(definition, value)
    end
    return if values.empty?

    deal.ai_filled_keys = values.keys
    deal.merge_custom_attributes(values)
  end

  def instructions
    'Fill the fields listed in the schema with values the customer clearly stated in the messages. Use null when the ' \
      'messages do not say it; never guess. Dates are YYYY-MM-DD.'
  end

  def schema
    properties = @definitions.to_h { |definition| [definition.attribute_key, field_schema(definition)] }
    { type: 'object', properties: properties, required: properties.keys, additionalProperties: false }
  end

  def field_schema(definition)
    description = [definition.attribute_display_name, definition.attribute_description].compact_blank.join(': ')
    case definition.attribute_display_type
    when 'number', 'currency', 'percent' then { type: %w[number null], description: description }
    when 'checkbox' then { type: %w[boolean null], description: description }
    when 'list' then { type: %w[string null], enum: Array(definition.attribute_values) + [nil], description: description }
    else { type: %w[string null], description: description }
    end
  end

  def event_name
    'crm_deal_fields'
  end
end
