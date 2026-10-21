class CreateCrmContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_contacts do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      # O Chatwoot apaga contatos fisicamente; o vínculo do CRM (e os deals) vão junto.
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :additional_attributes, null: false, default: {}

      t.timestamps
    end
    add_index :crm_contacts, [:account_id, :contact_id], unique: true
  end
end
