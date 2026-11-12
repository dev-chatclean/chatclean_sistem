class AddReportIndexesToCrmDeals < ActiveRecord::Migration[7.2]
  def change
    add_index :crm_deals, [:account_id, :created_at]
    add_index :crm_deals, [:account_id, :closed_at]
  end
end
