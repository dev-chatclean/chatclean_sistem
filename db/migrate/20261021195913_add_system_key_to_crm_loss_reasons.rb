class AddSystemKeyToCrmLossReasons < ActiveRecord::Migration[7.2]
  def change
    # Motivos usados por automações (ex.: "contact_blocked"); não podem ser desativados.
    add_column :crm_loss_reasons, :system_key, :string
    add_index :crm_loss_reasons, [:account_id, :system_key], unique: true, where: 'system_key IS NOT NULL'
  end
end
