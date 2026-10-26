class Chatclean::CannedResponseTeam < Chatclean::ApplicationRecord
  belongs_to :canned_response, class_name: '::CannedResponse', inverse_of: :chatclean_canned_response_teams
  belongs_to :team, class_name: '::Team'
end
