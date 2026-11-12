class AddRequirementsToCrmStages < ActiveRecord::Migration[7.2]
  def change
    change_table :crm_stages, bulk: true do |t|
      t.integer :stale_after_days
      t.jsonb :requirements, null: false, default: {}
    end
    add_index :crm_stages, 'pipeline_id, LOWER(name)', unique: true, name: 'index_crm_stages_on_pipeline_id_and_lower_name'
  end
end
