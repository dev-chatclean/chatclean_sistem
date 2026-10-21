class CreateCrmPipelines < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_pipelines do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end
    add_index :crm_pipelines, :account_id, unique: true, where: 'is_default', name: 'index_crm_pipelines_on_default_per_account'
  end
end
