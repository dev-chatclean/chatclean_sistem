class AddLeadSourceToCrmDeals < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_deals, :conversation_id, :bigint
    add_column :crm_deals, :lead_origin, :string
    add_column :crm_deals, :lead_source, :string
    add_index :crm_deals, :conversation_id
  end
end
