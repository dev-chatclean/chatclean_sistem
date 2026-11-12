class AddCustomAttributesToCrmDeals < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_deals, :custom_attributes, :jsonb, null: false, default: {}
  end
end
