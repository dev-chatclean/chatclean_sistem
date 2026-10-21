# == Schema Information
#
# Table name: crm_stages
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  position        :integer          default(0), not null
#  probability     :integer          default(0), not null
#  status          :integer          default("open"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  crm_pipeline_id :bigint           not null
#
# Indexes
#
#  index_crm_stages_on_account_id_and_crm_pipeline_id     (account_id,crm_pipeline_id)
#  index_crm_stages_on_crm_pipeline_id_and_position       (crm_pipeline_id,position)
#  index_crm_stages_on_one_won_and_one_lost_per_pipeline  (crm_pipeline_id,status) UNIQUE WHERE (status <> 0)
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

  # Ganho e Perdido são os estágios sistêmicos de cada pipeline, sempre depois dos abertos.
  WON_POSITION = 1000
  LOST_POSITION = 1001

  # O status do estágio define o status dos deals que estão nele (ver Crm::Deal).
  enum :status, { open: 0, won: 1, lost: 2 }

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :probability, numericality: { only_integer: true, in: 0..100 }
  validates :status, uniqueness: { scope: :crm_pipeline_id, message: ->(*) { I18n.t('errors.crm.stage.single_closing_stage') } },
                     unless: :open?
  validate :pipeline_from_same_account
  validate :closing_stage_unchanged, on: :update

  before_create :append_to_open_stages, if: :open?
  before_destroy :ensure_without_deals
  before_destroy :ensure_not_closing_stage

  def closing_stage?
    status_in_database.in?(%w[won lost])
  end

  private

  def append_to_open_stages
    self.position = pipeline.stages.open.maximum(:position).to_i + 1
  end

  def closing_stage_unchanged
    return unless closing_stage? && (will_save_change_to_status? || will_save_change_to_probability?)

    errors.add(:base, I18n.t('errors.crm.stage.closing_stage_immutable'))
  end

  # Ganho e Perdido só saem junto com o pipeline (dependent: :destroy).
  def ensure_not_closing_stage
    return if destroyed_by_association || !closing_stage?

    errors.add(:base, I18n.t('errors.crm.stage.closing_stage_undeletable'))
    throw :abort
  end

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
