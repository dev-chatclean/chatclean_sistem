class AddProbabilityToCrmStages < ActiveRecord::Migration[7.2]
  # Estágios sistêmicos de cada pipeline (CCV2-14): sempre no fim do funil.
  WON = 1
  LOST = 2

  def up
    add_column :crm_stages, :probability, :integer, null: false, default: 0
    add_check_constraint :crm_stages, 'probability BETWEEN 0 AND 100', name: 'crm_stages_probability_range'

    # Pipelines criados antes desta história ganham "Ganho" e "Perdido".
    { WON => ['Ganho', 100, 1000], LOST => ['Perdido', 0, 1001] }.each do |status, (name, probability, position)|
      execute <<~SQL.squish
        INSERT INTO crm_stages (account_id, crm_pipeline_id, name, status, probability, position, created_at, updated_at)
        SELECT p.account_id, p.id, #{connection.quote(name)}, #{status}, #{probability}, #{position}, NOW(), NOW()
        FROM crm_pipelines p
        WHERE NOT EXISTS (SELECT 1 FROM crm_stages s WHERE s.crm_pipeline_id = p.id AND s.status = #{status})
      SQL
      execute "UPDATE crm_stages SET probability = #{probability} WHERE status = #{status}"
    end

    # Um único estágio de ganho e um de perda por pipeline.
    add_index :crm_stages, [:crm_pipeline_id, :status], unique: true, where: 'status <> 0',
                                                        name: 'index_crm_stages_on_one_won_and_one_lost_per_pipeline'
  end

  def down
    remove_index :crm_stages, name: 'index_crm_stages_on_one_won_and_one_lost_per_pipeline'
    remove_check_constraint :crm_stages, name: 'crm_stages_probability_range'
    remove_column :crm_stages, :probability
  end
end
