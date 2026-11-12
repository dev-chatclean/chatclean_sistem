# Campos personalizados do negócio (US 33 / US 07): definidos em Configurações → Atributos personalizados (modelo "Negócio").
module CrmDealCustomFields
  extend ActiveSupport::Concern

  NUMBER_PATTERN = /\A-?\d+(\.\d+)?\z/

  included do
    validate :custom_attributes_match_definitions, if: :will_save_change_to_custom_attributes?
  end

  # Partial update, like contacts: blank values remove the key.
  def merge_custom_attributes(values)
    self.custom_attributes = custom_attributes.merge(values).compact_blank
  end

  private

  def deal_attribute_definitions
    @deal_attribute_definitions ||= account.custom_attribute_definitions.deal_attribute.index_by(&:attribute_key)
  end

  def custom_attributes_match_definitions
    invalid = custom_attributes.filter_map do |key, value|
      definition = deal_attribute_definitions[key]
      definition.attribute_display_name if definition && !valid_custom_value?(definition, value)
    end
    errors.add(:base, I18n.t('crm.deals.errors.invalid_custom_fields', fields: invalid.to_sentence)) if invalid.any?
  end

  def valid_custom_value?(definition, value)
    case definition.attribute_display_type
    when 'number', 'currency', 'percent' then value.is_a?(Numeric) || value.to_s.match?(NUMBER_PATTERN)
    when 'date' then iso_date?(value)
    when 'checkbox' then [true, false].include?(value)
    when 'list' then Array(definition.attribute_values).include?(value)
    else value.is_a?(String)
    end
  end

  def iso_date?(value)
    Date.iso8601(value.to_s)
    true
  rescue Date::Error
    false
  end

  # Names of the fields the stage requires and the deal lacks. Keys whose definition was deleted are ignored,
  # and a new deal is not checked, like the document requirement.
  def missing_custom_fields
    return [] if new_record?

    Array(stage.requirements['required_custom_fields']).filter_map do |key|
      definition = deal_attribute_definitions[key]
      definition.attribute_display_name if definition && custom_attributes[key].blank?
    end
  end

  def record_custom_field_events
    before, after = saved_change_to_custom_attributes
    (before.keys | after.keys).each do |key|
      next if before[key] == after[key]

      name = deal_attribute_definitions[key]&.attribute_display_name || key
      record_event('custom_field_changed', data: { 'field' => name, 'from' => before[key], 'to' => after[key] }.compact)
    end
  end
end
