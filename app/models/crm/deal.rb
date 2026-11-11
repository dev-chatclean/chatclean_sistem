class Crm::Deal < ApplicationRecord
  self.table_name = 'crm_deals'

  WIN_REASONS = %w[not_informed best_price delivery_time relationship referral product_features other].freeze
  LOSS_REASONS = %w[price no_interest competitor no_response out_of_profile other].freeze
  MAX_VALUE = 10**10

  belongs_to :account
  belongs_to :pipeline, class_name: 'Crm::Pipeline'
  belongs_to :stage, class_name: 'Crm::Stage'
  belongs_to :contact, optional: true
  belongs_to :company, optional: true
  belongs_to :assignee, class_name: 'User'
  has_many :events, -> { order(:created_at, :id) }, class_name: 'Crm::DealEvent', inverse_of: :deal, dependent: :delete_all

  enum :status, { open: 0, won: 1, lost: 2 }

  validates :title, length: { maximum: 120 }
  validates :value, numericality: { greater_than_or_equal_to: 0, less_than: MAX_VALUE }
  validate :title_or_party_present
  validate :close_reason_allowed
  validate :references_belong_to_account
  validate :stage_requirements_met, if: -> { will_save_change_to_stage_id? || new_record? }

  before_validation :sync_with_stage
  before_create :assign_number
  after_create :record_creation
  after_update :record_changes

  scope :board_visible, lambda { |since|
    where(status: :open).or(where(status: %i[won lost]).where(closed_at: since..))
  }

  def display_name
    title.presence || contact&.name.presence || company&.name.to_s
  end

  def journey
    entries = []
    events.each do |event|
      next if event.data['to_stage_name'].blank?

      entries.last[:left_at] = event.created_at if entries.any?
      entries << { stage_name: event.data['to_stage_name'], entered_at: event.created_at, left_at: nil }
    end
    entries
  end

  private

  def sync_with_stage
    return if stage.blank?

    self.pipeline = stage.pipeline
    self.stage_entered_at = Time.current if new_record? || will_save_change_to_stage_id?
    target_status = { 'won' => 'won', 'lost' => 'lost' }.fetch(stage.stage_type, 'open')
    apply_status(target_status) unless status == target_status && persisted?
  end

  def apply_status(target_status)
    self.status = target_status
    return self.closed_at = self.close_reason = self.close_note = nil if open?

    self.closed_at = Time.current
    self.close_reason = nil unless will_save_change_to_close_reason?
    self.close_note = nil unless will_save_change_to_close_note?
  end

  def assign_number
    account.lock!
    self.number = account.crm_deals.maximum(:number).to_i + 1
  end

  def title_or_party_present
    return if title.present? || contact_id.present? || company_id.present?

    errors.add(:base, I18n.t('crm.deals.errors.title_required'))
  end

  def close_reason_allowed
    if lost? && LOSS_REASONS.exclude?(close_reason)
      errors.add(:base, I18n.t('crm.deals.errors.loss_reason_required'))
    elsif won? && close_reason.present? && WIN_REASONS.exclude?(close_reason)
      errors.add(:base, I18n.t('crm.deals.errors.invalid_win_reason'))
    end
  end

  def references_belong_to_account
    { stage: 'invalid_stage', contact: 'invalid_contact', company: 'invalid_company' }.each do |association, error_key|
      record = public_send(association)
      errors.add(:base, I18n.t("crm.deals.errors.#{error_key}")) if record && record.account_id != account_id
    end
    errors.add(:base, I18n.t('crm.deals.errors.invalid_assignee')) if assignee && !account.users.exists?(id: assignee_id)
  end

  def stage_requirements_met
    missing = missing_requirements
    return if missing.empty?

    fields = missing.map { |key| I18n.t("crm.deals.requirements.#{key}") }.to_sentence
    errors.add(:base, I18n.t('crm.deals.errors.stage_requirements', stage: stage.name, fields: fields))
  end

  def missing_requirements
    requirements = stage&.requirements || {}
    missing = []
    missing << 'expected_close_date' if requirements['require_expected_close_date'] && expected_close_date.blank?
    missing << 'positive_value' if requirements['require_positive_value'] && !value.to_d.positive?
    missing
  end

  def record_creation
    record_event('created', to_stage: stage)
  end

  def record_changes
    if saved_change_to_stage_id?
      from_stage = Crm::Stage.find_by(id: stage_id_before_last_save)
      record_event(stage_event_type, from_stage: from_stage, to_stage: stage)
    end
    return unless saved_change_to_assignee_id?

    record_event('assignee_changed', data: { 'from' => User.find_by(id: assignee_id_before_last_save)&.name, 'to' => assignee.name })
  end

  def stage_event_type
    return status if saved_change_to_status? && !open?
    return 'reopened' if saved_change_to_status? && open?

    'stage_changed'
  end

  def record_event(event_type, from_stage: nil, to_stage: nil, data: {})
    events.create!(
      account: account, user: Current.user, event_type: event_type, from_stage: from_stage, to_stage: to_stage,
      data: data.merge('from_stage_name' => from_stage&.name, 'to_stage_name' => to_stage&.name).compact
    )
  end
end
