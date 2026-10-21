class AddConversationIdToCrmDeals < ActiveRecord::Migration[7.2]
  def change
    # Conversa de origem do deal; se a conversa for apagada no Chatwoot, o deal fica sem origem (FA 5.4).
    add_reference :crm_deals, :conversation, foreign_key: { on_delete: :nullify }
  end
end
