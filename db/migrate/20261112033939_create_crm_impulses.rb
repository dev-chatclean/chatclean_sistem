class CreateCrmImpulses < ActiveRecord::Migration[7.2]
  def change
    create_impulses
    create_impulse_steps
    create_impulse_executions
  end

  private

  def create_impulses
    create_table :crm_stage_impulses do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :stage_id, null: false, index: true
      t.string :name, limit: 80, null: false
      t.boolean :active, null: false, default: true
      t.boolean :stop_on_reply, null: false, default: true
      t.timestamps
    end
  end

  def create_impulse_steps
    create_table :crm_stage_impulse_steps do |t|
      t.bigint :impulse_id, null: false, index: true
      t.integer :position, null: false
      t.integer :delay_minutes, null: false, default: 0
      t.string :message_type, limit: 20, null: false, default: 'text'
      t.text :content
      t.jsonb :template_params, null: false, default: {}
      t.timestamps
    end
  end

  def create_impulse_executions
    create_table :crm_deal_impulse_executions do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :deal_id, null: false
      t.bigint :step_id, null: false, index: true
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :executed_at
      t.string :failure_reason
      t.bigint :message_id
      t.timestamps
      t.index [:deal_id, :status]
    end
  end
end
