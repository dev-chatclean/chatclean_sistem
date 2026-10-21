# == Schema Information
#
# Table name: crm_loss_reasons
#
#  id          :bigint           not null, primary key
#  description :text
#  is_active   :boolean          default(TRUE), not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_loss_reasons_on_account_id_and_lower_name  (account_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Crm::LossReason < Crm::ApplicationRecord
  belongs_to :account
  has_many :deals, class_name: 'Crm::Deal', foreign_key: :crm_loss_reason_id, inverse_of: :loss_reason,
                   dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(Arel.sql('LOWER(crm_loss_reasons.name)')) }
end
