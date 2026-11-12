class AddPipelineAiToCrm < ActiveRecord::Migration[7.2]
  def change
    change_table :crm_deals, bulk: true do |t|
      t.integer :ai_temperature
      t.string :ai_temperature_reason, limit: 280
      t.text :ai_next_step
      t.datetime :ai_analyzed_at
    end

    create_table :crm_ai_usages do |t|
      t.bigint :account_id, null: false
      t.date :month, null: false
      t.bigint :input_tokens, null: false, default: 0
      t.bigint :output_tokens, null: false, default: 0
      t.decimal :cost_brl, precision: 12, scale: 6, null: false, default: 0
      t.timestamps
      t.index [:account_id, :month], unique: true
    end
  end
end
