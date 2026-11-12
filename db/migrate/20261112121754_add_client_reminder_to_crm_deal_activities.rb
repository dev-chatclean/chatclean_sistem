class AddClientReminderToCrmDealActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_deal_activities, :notify_client_before_minutes, :integer
    add_column :crm_deal_activities, :client_reminder, :jsonb, null: false, default: {}
    add_column :crm_deal_activities, :client_reminder_sent_at, :datetime
  end
end
