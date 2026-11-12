class CreateCrmDealFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_deal_files do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :deal_id, null: false, index: true
      t.bigint :uploaded_by_id, null: false
      t.string :category, limit: 30, null: false, default: 'other'
      t.timestamps
    end
  end
end
