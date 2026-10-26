class AddChatcleanScopeToCannedResponses < ActiveRecord::Migration[7.2]
  # Mensagens rápidas por departamento e por usuário (US 17, CCV2-25). As que já existem ficam
  # "Todos" (visibility 0) e sem dono, como eram no Chatwoot.
  def change
    add_reference :canned_responses, :owner, foreign_key: { to_table: :users, on_delete: :nullify }
    add_column :canned_responses, :visibility, :integer, null: false, default: 0

    # Departamentos da mensagem rápida com alcance "Departamentos".
    create_table :chatclean_canned_response_teams do |t|
      t.references :canned_response, type: :integer, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :team, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :chatclean_canned_response_teams, [:canned_response_id, :team_id], unique: true,
                                                                                 name: 'index_chatclean_canned_response_teams_on_response_and_team'
  end
end
