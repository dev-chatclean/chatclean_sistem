# == Schema Information
#
# Table name: crm_pipelines
#
#  id          :bigint           not null, primary key
#  description :text
#  is_default  :boolean          default(FALSE), not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_pipelines_on_account_id           (account_id)
#  index_crm_pipelines_on_default_per_account  (account_id) UNIQUE WHERE is_default
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Crm::Pipeline < Crm::ApplicationRecord
  belongs_to :account
  has_many :stages, -> { order(:position) }, class_name: 'Crm::Stage', foreign_key: :crm_pipeline_id,
                                             inverse_of: :pipeline, dependent: :destroy
  has_many :deals, through: :stages

  validates :name, presence: true

  # Marcar como padrão desmarca o anterior na mesma transação (o índice parcial garante um por conta).
  before_save :unset_other_defaults, if: -> { is_default? && will_save_change_to_is_default? }
  # Todo pipeline nasce com "Ganho" e "Perdido" no fim do funil (CCV2-14).
  after_create :create_closing_stages
  # Precisa rodar antes do dependent: :destroy dos estágios.
  before_destroy :ensure_without_deals, prepend: true

  # Reordena os estágios abertos; Ganho e Perdido ficam sempre no fim.
  # stage_ids precisa trazer exatamente os estágios abertos do pipeline.
  def reorder_open_stages!(stage_ids)
    ids = Array(stage_ids).map(&:to_i)
    open_stages = stages.open.index_by(&:id)
    unless ids.uniq.size == ids.size && ids.sort == open_stages.keys.sort
      errors.add(:base, I18n.t('errors.crm.pipeline.invalid_stage_order'))
      raise ActiveRecord::RecordInvalid, self
    end

    transaction do
      ids.each_with_index { |id, index| open_stages[id].update!(position: index) }
    end
    stages.reset
  end

  private

  def unset_other_defaults
    self.class.where(account_id: account_id, is_default: true).where.not(id: id).find_each do |pipeline|
      pipeline.update!(is_default: false)
    end
  end

  def create_closing_stages
    stages.create!(account: account, name: I18n.t('crm.stages.default_names.won'), status: :won,
                   probability: 100, position: Crm::Stage::WON_POSITION)
    stages.create!(account: account, name: I18n.t('crm.stages.default_names.lost'), status: :lost,
                   probability: 0, position: Crm::Stage::LOST_POSITION)
  end

  def ensure_without_deals
    return unless deals.exists?

    errors.add(:base, I18n.t('errors.crm.pipeline.has_deals'))
    throw :abort
  end
end
