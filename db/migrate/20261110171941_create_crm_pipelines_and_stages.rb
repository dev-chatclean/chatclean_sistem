class CreateCrmPipelinesAndStages < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_pipelines do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false, limit: 100
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end
    add_index :crm_pipelines, :account_id, unique: true, where: 'is_default', name: 'index_crm_pipelines_on_account_id_default'

    create_table :crm_stages do |t|
      t.references :account, null: false, index: true
      t.references :pipeline, null: false, index: false
      t.string :name, null: false, limit: 50
      t.integer :stage_type, null: false, default: 1
      t.string :color, null: false, limit: 7
      t.integer :position, null: false
      t.timestamps
    end
    add_index :crm_stages, [:pipeline_id, :position]
  end
end
