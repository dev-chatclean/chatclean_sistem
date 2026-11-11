class Crm::ActivityReminderJob < ApplicationJob
  queue_as :medium

  # The reminder time is passed along so a job left behind by a rescheduled activity does nothing.
  def perform(activity_id, remind_at)
    activity = Crm::DealActivity.find_by(id: activity_id)
    return if activity.nil? || activity.completed? || activity.remind_at.to_i != remind_at

    deal = activity.deal
    ActionCableBroadcastJob.perform_now(
      [activity.assignee.pubsub_token], 'crm.activity_reminder',
      { account_id: activity.account_id, id: activity.id, title: activity.title, due_at: activity.due_at.to_i,
        deal_id: deal.id, deal_number: deal.number, deal_name: deal.display_name, pipeline_id: deal.pipeline_id }
    )
  end
end
