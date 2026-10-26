class CreateChatcleanAccountSchedulesAndHolidays < ActiveRecord::Migration[7.2]
  # Horário de atendimento da conta e feriados (US 19, CCV2-27).
  def change
    create_account_schedules
    create_holidays
  end

  private

  # Um por conta. Em "por conta" (mode 1), o horário é copiado para todos os canais.
  def create_account_schedules
    create_table :chatclean_account_schedules do |t|
      t.references :account, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :mode, null: false, default: 0
      t.boolean :enabled, null: false, default: false
      t.string :timezone, null: false, default: 'America/Sao_Paulo'
      t.text :out_of_office_message
      t.jsonb :working_hours, null: false, default: []

      t.timestamps
    end
  end

  def create_holidays
    create_table :chatclean_holidays do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.string :name, null: false
      t.text :message

      t.timestamps
    end
    add_index :chatclean_holidays, [:account_id, :date], unique: true
  end
end
