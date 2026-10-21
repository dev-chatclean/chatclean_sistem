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
  validates :is_default, uniqueness: { scope: :account_id }, if: :is_default?

  # Precisa rodar antes do dependent: :destroy dos estágios.
  before_destroy :ensure_without_deals, prepend: true

  private

  def ensure_without_deals
    return unless deals.exists?

    errors.add(:base, I18n.t('errors.crm.pipeline.has_deals'))
    throw :abort
  end
end
