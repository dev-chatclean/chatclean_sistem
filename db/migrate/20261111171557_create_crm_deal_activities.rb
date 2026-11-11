class CreateCrmDealActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_deal_activities do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :deal_id, null: false, index: true
      t.bigint :assignee_id, null: false, index: true
      t.bigint :required_by_stage_id
      t.string :title, limit: 120, null: false
      t.integer :activity_type, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.datetime :due_at, null: false
      t.integer :duration_minutes
      t.integer :remind_before_minutes
      t.text :description
      t.integer :recurrence, null: false, default: 0
      t.jsonb :checklist, null: false, default: []
      t.datetime :completed_at
      t.timestamps
    end
  end
end
