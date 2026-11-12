# "Para quem está nesta etapa agora": a one-off message to the deals in a stage when the campaign is created.
# The audience is frozen at creation and the sends are spaced out in Sidekiq.
class Crm::StageCampaign < ApplicationRecord
  include CrmClientMessageFields

  self.table_name = 'crm_stage_campaigns'

  SEND_INTERVAL = 3.seconds
  MAX_STALE_DAYS = 365
  FILTERS_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'assignee_id' => { 'type' => 'integer' },
      'stale_days' => { 'type' => 'integer', 'minimum' => 1, 'maximum' => MAX_STALE_DAYS }
    },
    'additionalProperties' => false
  }.to_json.freeze

  belongs_to :account
  belongs_to :stage, class_name: 'Crm::Stage', inverse_of: :campaigns
  belongs_to :created_by, class_name: 'User'
  has_many :deliveries, class_name: 'Crm::DealCampaignDelivery', foreign_key: :campaign_id, inverse_of: :campaign, dependent: :delete_all

  enum :status, { running: 0, completed: 1, canceled: 2 }

  validates :name, presence: true, length: { maximum: 80 }
  validate :filters_valid
  validate :targets_present, on: :create

  before_validation :inherit_account, on: :create
  before_create -> { self.total_targets = target_ids.size }
  after_create :create_deliveries
  after_create_commit :schedule_deliveries

  # The stage's deals that match the filters, as the board shows them (closed ones only from the last 30 days).
  def matching_deals
    deals = stage.deals.board_visible(Crm::Deal::BOARD_CLOSED_WINDOW.ago)
    deals = deals.where(assignee_id: filters['assignee_id']) if filters['assignee_id']
    deals = deals.where(stage_entered_at: ..filters['stale_days'].days.ago) if filters['stale_days']
    deals
  end

  # A deal in a running campaign of the stage stays out of a new one until that one ends.
  def busy_deals
    matching_deals.where(id: Crm::DealCampaignDelivery.where(campaign: stage.campaigns.running).select(:deal_id))
  end

  def eligible_deals
    matching_deals.where.not(id: busy_deals.select(:id))
  end

  def preview
    filters_valid
    raise ActiveRecord::RecordInvalid, self if errors.any?

    eligible = eligible_deals
    with_contact = eligible.where.not(contact_id: nil).count
    { with_contact: with_contact, without_contact: eligible.count - with_contact, in_running_campaign: busy_deals.count }
  end

  def cancel_pending!
    with_lock do
      unless running?
        errors.add(:base, I18n.t('crm.campaigns.errors.not_running'))
        raise ActiveRecord::RecordInvalid, self
      end

      deliveries.scheduled.includes(:deal).find_each { |delivery| delivery.finish!(:canceled, failure_reason: 'campaign_canceled') }
      update!(status: :canceled)
    end
  end

  def complete_if_finished!
    update!(status: :completed) if running? && deliveries.scheduled.none?
  end

  private

  def inherit_account
    self.account = stage&.account
  end

  def filters_valid
    validates_with JsonSchemaValidator, schema: FILTERS_SCHEMA, attribute_resolver: ->(record) { record.filters }
  end

  def target_ids
    @target_ids ||= eligible_deals.where.not(contact_id: nil).order(:id).pluck(:id)
  end

  def targets_present
    return if errors.any?

    errors.add(:base, I18n.t('crm.campaigns.errors.no_eligible_deals')) if target_ids.empty?
  end

  def create_deliveries
    now = Time.current
    rows = target_ids.each_with_index.map do |deal_id, index|
      { account_id: account_id, campaign_id: id, deal_id: deal_id, scheduled_at: now + (index * SEND_INTERVAL), created_at: now, updated_at: now }
    end
    Crm::DealCampaignDelivery.insert_all!(rows) # rubocop:disable Rails/SkipsModelValidations -- built here from validated deals
  end

  def schedule_deliveries
    deliveries.pluck(:id, :scheduled_at).each do |delivery_id, scheduled_at|
      Crm::CampaignDeliveryJob.set(wait_until: scheduled_at).perform_later(delivery_id)
    end
  end
end
