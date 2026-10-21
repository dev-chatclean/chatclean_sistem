# == Schema Information
#
# Table name: crm_deals
#
#  id                  :bigint           not null, primary key
#  currency            :string           default("BRL"), not null
#  expected_close_date :date
#  loss_details        :text
#  status              :integer          default("open"), not null
#  title               :string           not null
#  value               :decimal(12, 2)   default(0.0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  assignee_id         :bigint
#  conversation_id     :bigint
#  crm_contact_id      :bigint           not null
#  crm_loss_reason_id  :bigint
#  crm_stage_id        :bigint           not null
#
# Indexes
#
#  index_crm_deals_on_account_id_and_crm_stage_id  (account_id,crm_stage_id)
#  index_crm_deals_on_account_id_and_status        (account_id,status)
#  index_crm_deals_on_assignee_id                  (assignee_id)
#  index_crm_deals_on_conversation_id              (conversation_id)
#  index_crm_deals_on_crm_contact_id_and_status    (crm_contact_id,status)
#  index_crm_deals_on_crm_loss_reason_id           (crm_loss_reason_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (assignee_id => users.id) ON DELETE => nullify
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => nullify
#  fk_rails_...  (crm_contact_id => crm_contacts.id) ON DELETE => cascade
#  fk_rails_...  (crm_loss_reason_id => crm_loss_reasons.id)
#  fk_rails_...  (crm_stage_id => crm_stages.id)
#
class Crm::Deal < Crm::ApplicationRecord
  belongs_to :account
  belongs_to :crm_contact, class_name: 'Crm::Contact', inverse_of: :deals
  belongs_to :stage, class_name: 'Crm::Stage', foreign_key: :crm_stage_id, inverse_of: :deals
  belongs_to :assignee, class_name: '::User', optional: true
  belongs_to :loss_reason, class_name: 'Crm::LossReason', foreign_key: :crm_loss_reason_id, inverse_of: :deals, optional: true
  # Conversa do Chatwoot que originou o deal. Imutável depois de definida (CA 5.9).
  belongs_to :conversation, class_name: '::Conversation', optional: true
  has_one :pipeline, through: :stage

  enum :status, { open: 0, won: 1, lost: 2 }

  scope :in_pipeline, ->(pipeline_id) { joins(:stage).where(crm_stages: { crm_pipeline_id: pipeline_id }) }
  scope :for_contact, ->(contact_id) { joins(:crm_contact).where(crm_contacts: { contact_id: contact_id }) }

  # Histórico de funil e reaberturas (FA 3.2). Fica em deal.audits, fora da tela de auditoria da conta.
  audited only: %i[crm_stage_id status crm_loss_reason_id loss_details value assignee_id conversation_id]

  validates :title, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[BRL] }
  validates :loss_reason, presence: { message: ->(*) { I18n.t('errors.crm.deal.loss_reason_required') } }, if: :lost?
  validate :records_from_same_account
  validate :assignee_is_account_agent
  validate :loss_reason_usable, if: -> { lost? && (will_save_change_to_crm_loss_reason_id? || will_save_change_to_status?) }
  validate :contact_not_blocked, on: :create
  validate :conversation_unchanged, on: :update
  validate :conversation_from_deal_contact, if: :conversation

  # Mover o deal de estágio define o status: estágio "won" ganha, "lost" perde, "open" reabre.
  before_validation :apply_stage_status, if: :will_save_change_to_crm_stage_id?
  before_save :clear_loss, unless: :lost?

  private

  def apply_stage_status
    self.status = stage.status if stage
  end

  def clear_loss
    self.loss_reason = nil
    self.loss_details = nil
  end

  # Também barra apagar o vínculo; só o ON DELETE SET NULL do banco limpa a origem (FA 5.4).
  def conversation_unchanged
    return unless will_save_change_to_conversation_id? && conversation_id_in_database.present?

    errors.add(:conversation_id, I18n.t('errors.crm.deal.conversation_readonly'))
  end

  def conversation_from_deal_contact
    if conversation.account_id != account_id
      errors.add(:conversation_id, I18n.t('errors.crm.different_account'))
    elsif crm_contact.present? && conversation.contact_id != crm_contact.contact_id
      errors.add(:conversation_id, I18n.t('errors.crm.deal.conversation_other_contact'))
    end
  end

  def records_from_same_account
    { stage: stage, crm_contact: crm_contact, loss_reason: loss_reason }.each do |name, record|
      errors.add(name, I18n.t('errors.crm.different_account')) if record && record.account_id != account_id
    end
  end

  def loss_reason_usable
    return if loss_reason.blank? || loss_reason.is_active?

    errors.add(:loss_reason, I18n.t('errors.crm.deal.inactive_loss_reason'))
  end

  def contact_not_blocked
    return unless crm_contact&.contact&.blocked?

    errors.add(:crm_contact, I18n.t('errors.crm.deal.blocked_contact'))
  end

  def assignee_is_account_agent
    return if assignee.blank? || account&.users&.exists?(assignee.id)

    errors.add(:assignee, I18n.t('errors.crm.different_account'))
  end
end
