class Crm::ClientReminderJob < ApplicationJob
  queue_as :medium

  # The reminder time is passed along so a job left behind by a rescheduled activity does nothing.
  def perform(activity_id, remind_at)
    activity = Crm::DealActivity.find_by(id: activity_id)
    return if activity.nil? || activity.completed? || activity.client_reminder_sent_at || activity.client_remind_at.to_i != remind_at

    activity.send_client_reminder!
  end
end
