# == Schema Information
#
# Table name: crm_deals
#
#  id                  :bigint           not null, primary key
#  currency            :string           default("BRL"), not null
#  expected_close_date :date
#  status              :integer          default("open"), not null
#  title               :string           not null
#  value               :decimal(12, 2)   default(0.0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  assignee_id         :bigint
#  crm_contact_id      :bigint           not null
#  crm_stage_id        :bigint           not null
#
# Indexes
#
#  index_crm_deals_on_account_id_and_crm_stage_id  (account_id,crm_stage_id)
#  index_crm_deals_on_assignee_id                  (assignee_id)
#  index_crm_deals_on_crm_contact_id               (crm_contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (assignee_id => users.id) ON DELETE => nullify
#  fk_rails_...  (crm_contact_id => crm_contacts.id) ON DELETE => cascade
#  fk_rails_...  (crm_stage_id => crm_stages.id)
#
class Crm::Deal < Crm::ApplicationRecord
  belongs_to :account
  belongs_to :crm_contact, class_name: 'Crm::Contact', inverse_of: :deals
  belongs_to :stage, class_name: 'Crm::Stage', foreign_key: :crm_stage_id, inverse_of: :deals
  belongs_to :assignee, class_name: '::User', optional: true
  has_one :pipeline, through: :stage

  enum :status, { open: 0, won: 1, lost: 2 }

  validates :title, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validate :records_from_same_account
  validate :assignee_is_account_agent

  # Mover o deal de estágio define o status: estágio "won" ganha, "lost" perde, "open" reabre.
  before_validation :apply_stage_status, if: :will_save_change_to_crm_stage_id?

  private

  def apply_stage_status
    self.status = stage.status if stage
  end

  def records_from_same_account
    { stage: stage, crm_contact: crm_contact }.each do |name, record|
      errors.add(name, I18n.t('errors.crm.different_account')) if record && record.account_id != account_id
    end
  end

  def assignee_is_account_agent
    return if assignee.blank? || account&.users&.exists?(assignee.id)

    errors.add(:assignee, I18n.t('errors.crm.different_account'))
  end
end
