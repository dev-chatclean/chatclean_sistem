# == Schema Information
#
# Table name: crm_contacts
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  contact_id            :bigint           not null
#
# Indexes
#
#  index_crm_contacts_on_account_id_and_contact_id  (account_id,contact_id) UNIQUE
#  index_crm_contacts_on_contact_id                 (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#

# Vínculo 1:1 entre o CRM e o contato nativo do Chatwoot (::Contact), sem alterar a tabela contacts.
class Crm::Contact < Crm::ApplicationRecord
  belongs_to :account
  belongs_to :contact, class_name: '::Contact'
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_contact_id, inverse_of: :crm_contact, dependent: :destroy

  validates :contact_id, uniqueness: { scope: :account_id }
  validate :contact_from_same_account

  # Devolve o vínculo existente ou cria um. Se duas requisições criarem ao mesmo tempo,
  # o índice único barra a segunda e ela recebe o registro da primeira.
  def self.for_contact!(contact)
    find_or_create_by!(account_id: contact.account_id, contact_id: contact.id)
  rescue ActiveRecord::RecordNotUnique
    find_by!(account_id: contact.account_id, contact_id: contact.id)
  end

  private

  def contact_from_same_account
    return if contact.blank? || contact.account_id == account_id

    errors.add(:contact, I18n.t('errors.crm.different_account'))
  end
end
