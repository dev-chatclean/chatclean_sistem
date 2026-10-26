# Registro de um fechamento feito por uma pessoa: motivo, quem fechou, quando e o valor da venda (CA 16.7).
# == Schema Information
#
# Table name: chatclean_conversation_closures
#
#  id                :bigint           not null, primary key
#  sale_value        :decimal(12, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  closing_reason_id :bigint           not null
#  conversation_id   :bigint           not null
#  crm_deal_id       :bigint
#  user_id           :bigint
#
# Indexes
#
#  index_chatclean_conversation_closures_on_account_and_created_at  (account_id,created_at)
#  index_chatclean_conversation_closures_on_closing_reason_id       (closing_reason_id)
#  index_chatclean_conversation_closures_on_conversation_id         (conversation_id)
#  index_chatclean_conversation_closures_on_crm_deal_id             (crm_deal_id)
#  index_chatclean_conversation_closures_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (closing_reason_id => chatclean_closing_reasons.id)
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (crm_deal_id => crm_deals.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class Chatclean::ConversationClosure < Chatclean::ApplicationRecord
  belongs_to :account
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :closing_reason, class_name: 'Chatclean::ClosingReason', inverse_of: :closures
  belongs_to :user, class_name: '::User', optional: true
  belongs_to :crm_deal, class_name: 'Crm::Deal', optional: true

  validates :sale_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
