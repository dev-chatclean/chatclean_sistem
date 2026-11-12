# "Lembrar o cliente antes": a message to the deal's contact some time before the activity.
module CrmActivityClientReminder
  extend ActiveSupport::Concern

  CLIENT_REMINDER_OPTIONS = [15, 30, 60, 1440].freeze

  included do
    validates :notify_client_before_minutes, inclusion: { in: CLIENT_REMINDER_OPTIONS }, allow_nil: true
    validate :client_reminder_valid, if: -> { notify_client_before_minutes && (new_record? || client_reminder_settings_changed?) }

    before_save :reset_client_reminder, if: -> { will_save_change_to_due_at? || will_save_change_to_notify_client_before_minutes? }
    after_commit :schedule_client_reminder, on: [:create, :update], if: :client_reminder_changed?
    after_update :record_client_reminder_canceled, if: :client_reminder_canceled_by_update?
    after_destroy :record_client_reminder_canceled,
                  if: -> { !completed? && client_reminder_pending?(notify_client_before_minutes, due_at, client_reminder_sent_at) }
  end

  def client_remind_at
    due_at - notify_client_before_minutes.minutes if notify_client_before_minutes && due_at
  end

  def send_client_reminder!
    sender = Crm::ClientMessageService.new(deal: deal, message_type: client_reminder['message_type'], content: client_reminder['content'],
                                           template_params: client_reminder['template_params'] || {}, variables: client_reminder_variables)
    message = sender.perform
    update!(client_reminder_sent_at: Time.current) if message
    deal.events.create!(account: account, event_type: message ? 'client_reminder_sent' : 'client_reminder_failed',
                        data: { 'activity' => title, 'reason' => sender.failure_reason }.compact)
  end

  private

  def client_reminder_valid
    error = client_reminder_error
    errors.add(:base, I18n.t("crm.activities.errors.#{error}")) if error
  end

  def client_reminder_error
    return 'client_reminder_no_contact' if deal.contact.nil?
    return 'client_reminder_time_zone' unless ActiveSupport::TimeZone[client_reminder['time_zone'].to_s]

    template = client_reminder['template_params'].to_h
    complete = case client_reminder['message_type']
               when 'text' then client_reminder['content'].present?
               when 'template' then template['name'].present? && template['language'].present?
               end
    'client_reminder_content' unless complete
  end

  def client_reminder_settings_changed?
    will_save_change_to_notify_client_before_minutes? || will_save_change_to_client_reminder?
  end

  def client_reminder_pending?(minutes, due, sent_at)
    minutes.present? && sent_at.nil? && (due - minutes.minutes).future?
  end

  # Turning the reminder off or completing the activity drops a reminder that was still waiting.
  def client_reminder_canceled_by_update?
    return false unless client_reminder_pending?(notify_client_before_minutes_before_last_save, due_at_before_last_save,
                                                 client_reminder_sent_at_before_last_save)

    notify_client_before_minutes.nil? || (saved_change_to_completed_at? && completed?)
  end

  def record_client_reminder_canceled
    deal.events.create!(account: account, user: Current.user, event_type: 'client_reminder_canceled', data: { 'activity' => title })
  end

  def reset_client_reminder
    self.client_reminder_sent_at = nil
  end

  def client_reminder_changed?
    (saved_change_to_due_at? || saved_change_to_notify_client_before_minutes? || saved_change_to_id?) && client_remind_at && !completed?
  end

  def schedule_client_reminder
    return if client_remind_at.past?

    Crm::ClientReminderJob.set(wait_until: client_remind_at).perform_later(id, client_remind_at.to_i)
  end

  def client_reminder_variables
    # The time zone of the browser that scheduled the activity, so the client reads the time that was picked.
    local_due_at = due_at.in_time_zone(client_reminder['time_zone'])
    { 'activity.title' => title, 'activity.date' => local_due_at.strftime('%d/%m/%Y'), 'activity.time' => local_due_at.strftime('%H:%M') }
  end
end
