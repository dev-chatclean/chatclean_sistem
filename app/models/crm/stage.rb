class Crm::Stage < ApplicationRecord
  self.table_name = 'crm_stages'

  MAX_STALE_DAYS = 365
  REQUIREMENTS_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'require_owner' => { 'type' => 'boolean' },
      'required_custom_fields' => { 'type' => 'array', 'items' => { 'type' => 'string' } },
      'require_expected_close_date' => { 'type' => 'boolean' },
      'require_positive_value' => { 'type' => 'boolean' },
      'require_product' => { 'type' => 'boolean' },
      'required_tasks' => { 'type' => 'array', 'maxItems' => 20, 'items' => { 'type' => 'string', 'minLength' => 1, 'maxLength' => 120 } },
      'apply_labels' => { 'type' => 'array', 'items' => { 'type' => 'string' } },
      'require_document' => { 'type' => 'boolean' }
    },
    'additionalProperties' => false
  }.to_json.freeze

  belongs_to :account
  belongs_to :pipeline, class_name: 'Crm::Pipeline', inverse_of: :stages

  enum :stage_type, { initial: 0, custom: 1, won: 2, lost: 3 }

  validates :name, presence: true, length: { in: 2..50 }
  validates :color, format: { with: /\A#\h{6}\z/ }
  validates :position, presence: true
  validates :stale_after_days, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_STALE_DAYS }, allow_nil: true
  validates_with JsonSchemaValidator, schema: REQUIREMENTS_SCHEMA, attribute_resolver: ->(record) { record.requirements }
  validate :name_unique_in_pipeline

  before_validation :inherit_stale_after_days, on: :create

  def closing?
    won? || lost?
  end

  private

  def inherit_stale_after_days
    self.stale_after_days ||= pipeline.stale_after_days unless closing?
  end

  def name_unique_in_pipeline
    return if name.blank?

    siblings = pipeline.stages.reject { |stage| stage.equal?(self) || (persisted? && stage.id == id) }
    return unless siblings.any? { |stage| stage.name.to_s.strip.casecmp?(name.strip) }

    errors.add(:base, I18n.t('crm.stages.errors.duplicate_name', name: name.strip))
  end
end
