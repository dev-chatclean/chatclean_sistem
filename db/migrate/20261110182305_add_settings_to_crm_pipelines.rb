class AddSettingsToCrmPipelines < ActiveRecord::Migration[7.2]
  def change
    change_table :crm_pipelines, bulk: true do |t|
      t.text :description
      t.string :group_name, limit: 60
      t.integer :pipeline_type, null: false, default: 0
      t.string :item_label, null: false, default: 'deal', limit: 20
      t.string :item_label_custom, limit: 30
      t.integer :stale_after_days, null: false, default: 7
      t.boolean :one_card_per_contact, null: false, default: true
      t.jsonb :card_fields, null: false, default: []
    end
  end
end
