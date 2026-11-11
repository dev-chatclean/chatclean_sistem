class CreateCrmDeals < ActiveRecord::Migration[7.2]
  def change
    create_deals
    add_index :crm_deals, [:account_id, :number], unique: true
    add_index :crm_deals, [:account_id, :status]
    create_deal_events
  end

  private

  def create_deals
    create_table :crm_deals do |t|
      t.references :account, null: false, index: false
      t.references :pipeline, null: false
      t.references :stage, null: false
      t.references :contact
      t.references :company
      t.references :assignee, null: false
      t.integer :number, null: false
      t.string :title, limit: 120
      t.decimal :value, precision: 12, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.date :expected_close_date
      t.text :notes
      t.datetime :stage_entered_at, null: false
      t.datetime :closed_at
      t.string :close_reason, limit: 40
      t.text :close_note
      t.timestamps
    end
  end

  def create_deal_events
    create_table :crm_deal_events do |t|
      t.references :account, null: false
      t.references :deal, null: false
      t.references :user
      t.string :event_type, null: false, limit: 40
      t.references :from_stage
      t.references :to_stage
      t.jsonb :data, null: false, default: {}
      t.datetime :created_at, null: false
    end
  end
end
