class CreateCrmProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_products do |t|
      t.bigint :account_id, null: false, index: true
      t.string :name, limit: 120, null: false
      t.text :description
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.string :sku, limit: 60
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :crm_deal_products do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :deal_id, null: false, index: true
      t.bigint :product_id, null: false, index: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.timestamps
    end
  end
end
