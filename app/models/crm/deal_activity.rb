class Crm::DealActivity < ApplicationRecord
  include CrmActivityClientReminder

  self.table_name = 'crm_deal_activities'

  MAX_DURATION_MINUTES = 24 * 60
  MAX_REMIND_BEFORE_MINUTES = 7 * 24 * 60
  RECURRENCE_STEPS = { 'daily' => 1.day, 'weekly' => 1.week, 'monthly' => 1.month }.freeze
  CHECKLIST_SCHEMA = {
    'type' => 'array',
    'maxItems' => 30,
    'items' => {
      'type' => 'object',
      'properties' => {
        'title' => { 'type' => 'string', 'minLength' => 1, 'maxLength' => 120 },
        'done' => { 'type' => 'boolean' }
      },
      'required' => %w[title done],
      'additionalProperties' => false
    }
  }.to_json.freeze

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :activities
  belongs_to :assignee, class_name: 'User'
  belongs_to :required_by_stage, class_name: 'Crm::Stage', optional: true

  enum :activity_type, { call: 0, follow_up: 1, meeting: 2, internal: 3 }, validate: true
  enum :priority, { low: 0, medium: 1, high: 2 }, prefix: true, validate: true
  enum :recurrence, { never: 0, daily: 1, weekly: 2, monthly: 3 }, prefix: true, validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :due_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_DURATION_MINUTES }, allow_nil: true
  validates :remind_before_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_REMIND_BEFORE_MINUTES }, allow_nil: true
  validates_with JsonSchemaValidator, schema: CHECKLIST_SCHEMA, attribute_resolver: ->(record) { record.checklist }
  validate :assignee_belongs_to_account
  validate :required_tasks_do_not_repeat

  scope :pending, -> { where(completed_at: nil) }

  before_validation :inherit_account, on: :create
  after_create { record_deal_event('activity_created') }
  after_update :handle_completion, if: :saved_change_to_completed_at?
  after_commit :schedule_reminder, on: [:create, :update], if: :reminder_changed?

  def completed?
    completed_at.present?
  end

  def remind_at
    due_at - remind_before_minutes.minutes if remind_before_minutes && due_at
  end

  private

  def inherit_account
    self.account = deal&.account
  end

  def assignee_belongs_to_account
    errors.add(:base, I18n.t('crm.deals.errors.invalid_assignee')) if assignee && account && !account.users.exists?(id: assignee_id)
  end

  def required_tasks_do_not_repeat
    errors.add(:recurrence, :invalid) if required_by_stage_id && !recurrence_never?
  end

  def handle_completion
    return unless completed?

    record_deal_event('activity_completed')
    repeat_next_occurrence unless recurrence_never?
  end

  def repeat_next_occurrence
    next_due_at = due_at + RECURRENCE_STEPS.fetch(recurrence)
    deal.activities.create!(
      attributes.slice('assignee_id', 'title', 'activity_type', 'priority', 'duration_minutes', 'remind_before_minutes', 'description', 'recurrence',
                       'notify_client_before_minutes', 'client_reminder')
                .merge('due_at' => next_due_at, 'checklist' => checklist.map { |item| item.merge('done' => false) })
                .merge(deal.contact ? {} : { 'notify_client_before_minutes' => nil })
    )
  end

  def record_deal_event(event_type)
    deal.events.create!(account: account, user: Current.user, event_type: event_type, data: { 'activity' => title })
  end

  def reminder_changed?
    (saved_change_to_due_at? || saved_change_to_remind_before_minutes? || saved_change_to_id?) && remind_at && !completed?
  end

  def schedule_reminder
    return if due_at.past?

    Crm::ActivityReminderJob.set(wait_until: [remind_at, Time.current].max).perform_later(id, remind_at.to_i)
  end
end
