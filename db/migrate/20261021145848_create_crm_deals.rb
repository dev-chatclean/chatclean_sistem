class CreateCrmDeals < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_deals do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :crm_contact, null: false, foreign_key: { on_delete: :cascade }
      t.references :crm_stage, null: false, index: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :title, null: false
      t.decimal :value, precision: 12, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: 'BRL'
      t.date :expected_close_date
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :crm_deals, [:account_id, :crm_stage_id]
    add_check_constraint :crm_deals, 'value >= 0', name: 'crm_deals_value_non_negative'
  end
end
