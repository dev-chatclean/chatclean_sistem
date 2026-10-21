class AddLossReasonToCrmDeals < ActiveRecord::Migration[7.2]
  def change
    add_reference :crm_deals, :crm_loss_reason, foreign_key: true
    add_column :crm_deals, :loss_details, :text
    add_index :crm_deals, [:account_id, :status]
    add_index :crm_deals, [:crm_contact_id, :status]
    # Coberto pelo índice composto acima, que começa por crm_contact_id.
    remove_index :crm_deals, :crm_contact_id
    add_check_constraint :crm_deals, "currency = 'BRL'", name: 'crm_deals_currency_brl'
  end
end
