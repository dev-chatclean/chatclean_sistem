# Motivo de fechamento de atendimento (US 16, CCV2-24). Sem departamentos, vale para todos.
# == Schema Information
#
# Table name: chatclean_closing_reasons
#
#  id              :bigint           not null, primary key
#  ask_sale_value  :boolean          default(FALSE), not null
#  closing_message :text
#  is_active       :boolean          default(TRUE), not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#
# Indexes
#
#  index_chatclean_closing_reasons_on_account_id_and_lower_name  (account_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Chatclean::ClosingReason < Chatclean::ApplicationRecord
  belongs_to :account
  has_many :closing_reason_teams, class_name: 'Chatclean::ClosingReasonTeam', inverse_of: :closing_reason, dependent: :destroy
  has_many :teams, through: :closing_reason_teams
  # Motivo já usado não é excluído, só inativado (CA 16.2).
  has_many :closures, class_name: 'Chatclean::ConversationClosure', inverse_of: :closing_reason, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
  validate :teams_from_same_account

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(Arel.sql('LOWER(chatclean_closing_reasons.name)')) }
  # O administrador vê todos os motivos; o atendente, os gerais e os dos departamentos dele.
  scope :available_to, lambda { |account_user|
    next all if account_user.administrator?

    linked = Chatclean::ClosingReasonTeam.select(:closing_reason_id)
    own_teams = TeamMember.where(user_id: account_user.user_id).select(:team_id)
    where.not(id: linked).or(where(id: linked.where(team_id: own_teams)))
  }

  private

  def teams_from_same_account
    errors.add(:teams, I18n.t('errors.crm.different_account')) if teams.any? { |team| team.account_id != account_id }
  end
end
