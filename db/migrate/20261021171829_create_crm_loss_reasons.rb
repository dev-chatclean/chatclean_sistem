class CreateCrmLossReasons < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_loss_reasons do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
    # Nome único por conta sem diferenciar maiúsculas ("Preço alto" = "preço alto").
    add_index :crm_loss_reasons, 'account_id, lower(name)', unique: true, name: 'index_crm_loss_reasons_on_account_id_and_lower_name'
  end
end
