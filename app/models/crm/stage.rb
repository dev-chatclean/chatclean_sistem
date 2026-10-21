# == Schema Information
#
# Table name: crm_stages
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  position        :integer          default(0), not null
#  status          :integer          default("open"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  crm_pipeline_id :bigint           not null
#
# Indexes
#
#  index_crm_stages_on_account_id_and_crm_pipeline_id  (account_id,crm_pipeline_id)
#  index_crm_stages_on_crm_pipeline_id_and_position    (crm_pipeline_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (crm_pipeline_id => crm_pipelines.id)
#
class Crm::Stage < Crm::ApplicationRecord
  belongs_to :account
  belongs_to :pipeline, class_name: 'Crm::Pipeline', foreign_key: :crm_pipeline_id, inverse_of: :stages
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_stage_id, inverse_of: :stage, dependent: nil

  # O status do estágio define o status dos deals que estão nele (ver Crm::Deal).
  enum :status, { open: 0, won: 1, lost: 2 }

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :pipeline_from_same_account

  before_destroy :ensure_without_deals

  private

  def pipeline_from_same_account
    return if pipeline.blank? || pipeline.account_id == account_id

    errors.add(:pipeline, I18n.t('errors.crm.different_account'))
  end

  def ensure_without_deals
    return unless deals.exists?

    errors.add(:base, I18n.t('errors.crm.stage.has_deals'))
    throw :abort
  end
end
