class CreateCrmStageCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_campaigns
    create_deliveries
  end

  private

  def create_campaigns
    create_table :crm_stage_campaigns do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :stage_id, null: false, index: true
      t.bigint :created_by_id, null: false
      t.string :name, limit: 80, null: false
      t.integer :status, null: false, default: 0
      t.string :message_type, limit: 20, null: false, default: 'text'
      t.text :content
      t.jsonb :template_params, null: false, default: {}
      t.jsonb :filters, null: false, default: {}
      t.integer :total_targets, null: false, default: 0
      t.timestamps
    end
  end

  def create_deliveries
    create_table :crm_deal_campaign_deliveries do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :campaign_id, null: false
      t.bigint :deal_id, null: false, index: true
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :executed_at
      t.string :failure_reason
      t.bigint :message_id
      t.timestamps
      t.index [:campaign_id, :status]
    end
  end
end
