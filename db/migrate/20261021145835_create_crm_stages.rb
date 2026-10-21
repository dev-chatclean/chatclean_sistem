class CreateCrmStages < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_stages do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :crm_pipeline, null: false, index: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :crm_stages, [:account_id, :crm_pipeline_id]
    add_index :crm_stages, [:crm_pipeline_id, :position]
  end
end
