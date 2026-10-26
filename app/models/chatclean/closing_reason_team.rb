# == Schema Information
#
# Table name: chatclean_closing_reason_teams
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  closing_reason_id :bigint           not null
#  team_id           :bigint           not null
#
# Indexes
#
#  index_chatclean_closing_reason_teams_on_reason_and_team  (closing_reason_id,team_id) UNIQUE
#  index_chatclean_closing_reason_teams_on_team_id          (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (closing_reason_id => chatclean_closing_reasons.id) ON DELETE => cascade
#  fk_rails_...  (team_id => teams.id) ON DELETE => cascade
#
class Chatclean::ClosingReasonTeam < Chatclean::ApplicationRecord
  belongs_to :closing_reason, class_name: 'Chatclean::ClosingReason', inverse_of: :closing_reason_teams
  belongs_to :team, class_name: '::Team'
end
