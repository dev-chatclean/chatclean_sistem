# == Schema Information
#
# Table name: crm_pipelines
#
#  id         :bigint           not null, primary key
#  is_default :boolean          default(FALSE), not null
#  name       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_crm_pipelines_on_account_id          (account_id)
#  index_crm_pipelines_on_account_id_default  (account_id) UNIQUE WHERE is_default
#
class Crm::Pipeline < ApplicationRecord
  self.table_name = 'crm_pipelines'

  REQUIRED_STAGES = [
    { stage_type: :initial, color: '#1F93FF' },
    { stage_type: :won, color: '#44CE4B' },
    { stage_type: :lost, color: '#E0484E' }
  ].freeze

  belongs_to :account
  has_many :stages, -> { order(:position) }, class_name: 'Crm::Stage', inverse_of: :pipeline, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validate :default_cannot_be_unset, on: :update

  before_validation :become_default_if_first, on: :create
  before_save :unset_other_defaults, if: -> { is_default? && will_save_change_to_is_default? }
  before_create :build_required_stages

  private

  def become_default_if_first
    self.is_default = true unless account.crm_pipelines.exists?
  end

  def build_required_stages
    I18n.with_locale(account.locale) do
      REQUIRED_STAGES.each_with_index do |stage, position|
        stages.build(account: account, position: position, name: I18n.t("crm.stages.defaults.#{stage[:stage_type]}"), **stage)
      end
    end
  end

  def unset_other_defaults
    account.crm_pipelines.where(is_default: true).where.not(id: id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def default_cannot_be_unset
    return unless is_default_changed?(from: true, to: false)

    errors.add(:base, I18n.t('crm.pipelines.errors.default_cannot_be_unset'))
  end
end
