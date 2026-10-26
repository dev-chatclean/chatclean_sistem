class CreateChatcleanClosingReasons < ActiveRecord::Migration[7.2]
  # Motivos de fechamento (US 16, CCV2-24). As chaves estrangeiras seguem o CRM: os models do Chatwoot
  # (conta, departamento, atendimento, usuário) não recebem associações nossas, então a limpeza fica no banco.
  def change
    create_closing_reasons
    create_closing_reason_teams
    create_conversation_closures
  end

  private

  def create_closing_reasons
    create_table :chatclean_closing_reasons do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.boolean :is_active, null: false, default: true
      t.text :closing_message
      t.boolean :ask_sale_value, null: false, default: false

      t.timestamps
    end
    # Nome único por conta sem diferenciar maiúsculas ("Venda" = "venda").
    add_index :chatclean_closing_reasons, 'account_id, lower(name)', unique: true,
                                                                     name: 'index_chatclean_closing_reasons_on_account_id_and_lower_name'
  end

  # Departamentos do motivo. Sem nenhum, o motivo vale para todos.
  def create_closing_reason_teams
    create_table :chatclean_closing_reason_teams do |t|
      t.references :closing_reason, null: false, index: false, foreign_key: { to_table: :chatclean_closing_reasons, on_delete: :cascade }
      t.references :team, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :chatclean_closing_reason_teams, [:closing_reason_id, :team_id], unique: true,
                                                                               name: 'index_chatclean_closing_reason_teams_on_reason_and_team'
  end

  # Um registro por fechamento: reabrir e fechar de novo gera outro (CA 16.7).
  def create_conversation_closures
    create_table :chatclean_conversation_closures do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :closing_reason, null: false, foreign_key: { to_table: :chatclean_closing_reasons }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.decimal :sale_value, precision: 12, scale: 2
      t.references :crm_deal, foreign_key: { on_delete: :nullify }

      t.timestamps
    end
    add_index :chatclean_conversation_closures, [:account_id, :created_at],
              name: 'index_chatclean_conversation_closures_on_account_and_created_at'
  end
end
