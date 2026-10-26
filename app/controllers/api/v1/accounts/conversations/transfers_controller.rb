# ChatClean (US 15): "Transferir" para um departamento e/ou um atendente, com uma observação que
# vira nota interna de quem transferiu. Só para o departamento, o atendimento fica sem atendente,
# pendente no departamento. O atendente precisa ter acesso ao canal (FA 15.2).
class Api::V1::Accounts::Conversations::TransfersController < Api::V1::Accounts::Conversations::BaseController
  before_action :validate_target

  def create
    ActiveRecord::Base.transaction do
      @conversation.update!(team: team) if team
      ::Conversations::AssignmentService.new(conversation: @conversation, assignee_id: assignee&.id).perform
      Messages::MessageBuilder.new(Current.user, @conversation, { content: note, private: true }).perform if note.present?
    end
    head :ok
  end

  private

  def validate_target
    if team.blank? && params[:assignee_id].blank?
      render_could_not_create_error(I18n.t('chatclean.conversations.transfer.target_required'))
    elsif params[:assignee_id].present? && assignee.blank?
      render_could_not_create_error(I18n.t('chatclean.conversations.transfer.no_inbox_access'))
    end
  end

  def team
    @team ||= Current.account.teams.find(params[:team_id]) if params[:team_id].present?
  end

  def assignee
    @assignee ||= @conversation.inbox.assignable_agents.find { |user| user.id == params[:assignee_id].to_i }
  end

  def note
    params[:note].to_s.strip
  end
end
