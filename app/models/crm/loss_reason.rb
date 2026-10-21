# == Schema Information
#
# Table name: crm_loss_reasons
#
#  id          :bigint           not null, primary key
#  description :text
#  is_active   :boolean          default(TRUE), not null
#  name        :string           not null
#  system_key  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_loss_reasons_on_account_id_and_lower_name  (account_id, lower((name)::text)) UNIQUE
#  index_crm_loss_reasons_on_account_id_and_system_key  (account_id,system_key) UNIQUE WHERE (system_key IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Crm::LossReason < Crm::ApplicationRecord
  belongs_to :account
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_loss_reason_id, inverse_of: :loss_reason,
                   dependent: :restrict_with_error

  # Motivo usado pela perda automática de deals de contatos bloqueados (CCV2-15).
  CONTACT_BLOCKED = 'contact_blocked'.freeze

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
  validate :system_reason_stays_active

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(Arel.sql('LOWER(crm_loss_reasons.name)')) }

  # Devolve o motivo "Contato bloqueado" da conta, criando-o no idioma da conta na primeira vez.
  # Um motivo manual com o mesmo nome é adotado em vez de duplicado.
  def self.for_blocked_contact!(account)
    reasons = where(account: account)
    reasons.find_by(system_key: CONTACT_BLOCKED) || begin
      name = I18n.with_locale(account.locale) { I18n.t('crm.loss_reasons.contact_blocked') }
      reason = reasons.find_by('LOWER(name) = ?', name.downcase) || reasons.new(name: name)
      reason.update!(system_key: CONTACT_BLOCKED, is_active: true)
      reason
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def system_reason_stays_active
    return if system_key.blank? || is_active?

    errors.add(:is_active, I18n.t('errors.crm.loss_reason.system_reason_active'))
  end
end
