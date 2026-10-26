# Mensagens rápidas por departamento e por usuário, com anexos (US 17, CCV2-25), incluídas no
# CannedResponse do Chatwoot pelo initializer chatclean_hooks.
module Chatclean::CannedResponseScope
  extend ActiveSupport::Concern

  MAX_ATTACHMENTS_SIZE = 16.megabytes

  included do
    belongs_to :owner, class_name: 'User', optional: true
    has_many :chatclean_canned_response_teams, class_name: 'Chatclean::CannedResponseTeam', dependent: :destroy,
                                               inverse_of: :canned_response
    has_many :teams, through: :chatclean_canned_response_teams
    has_many_attached :attachments

    enum :visibility, { everyone: 0, teams: 1, personal: 2 }, prefix: :visible_to

    # Só a "Só eu" tem dono; as compartilhadas ficam sem, e o atalho fica único entre elas.
    before_validation -> { self.owner = nil }, unless: :visible_to_personal?
    validates :owner, presence: true, if: :visible_to_personal?
    validates :teams, presence: true, if: :visible_to_teams?
    validate :attachments_within_limit
    before_save -> { self.teams = [] }, unless: :visible_to_teams?

    # Cada um vê as de todos, as dos seus departamentos e as suas. O administrador vê todas as
    # compartilhadas e as suas; as dos outros usuários só quando pede (include_personal).
    scope :available_to, lambda { |account_user, include_personal: false|
      user_teams = TeamMember.where(user_id: account_user.user_id).select(:team_id)
      linked = Chatclean::CannedResponseTeam.select(:canned_response_id)
      shared = account_user.administrator? ? visible_to_teams : visible_to_teams.where(id: linked.where(team_id: user_teams))
      personal = account_user.administrator? && include_personal ? visible_to_personal : visible_to_personal.where(owner_id: account_user.user_id)
      visible_to_everyone.or(shared).or(personal)
    }
  end

  def as_json(options = nil)
    super.merge(
      'owner_id' => owner_id,
      'owner_name' => owner&.available_name,
      'team_ids' => teams.map(&:id),
      'attachments' => attachments.map do |attachment|
        { id: attachment.id, file_name: attachment.filename.to_s, file_size: attachment.byte_size, content_type: attachment.content_type,
          file_url: Rails.application.routes.url_helpers.rails_storage_proxy_path(attachment, only_path: true) }
      end
    )
  end

  private

  def attachments_within_limit
    return if attachments.sum { |attachment| attachment.blob.byte_size } <= MAX_ATTACHMENTS_SIZE

    errors.add(:attachments, I18n.t('chatclean.canned_responses.attachments_too_large'))
  end
end
