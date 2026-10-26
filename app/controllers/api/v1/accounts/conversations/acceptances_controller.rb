# ChatClean (US 15): "Aceitar" um atendimento. O atendimento é travado durante a atribuição, então
# só o primeiro atendente fica com ele; quem chegar depois recebe 409 com o nome de quem aceitou
# (FA 15.1). A atribuição em si é a do Chatwoot.
class Api::V1::Accounts::Conversations::AcceptancesController < Api::V1::Accounts::Conversations::BaseController
  def create
    accepted_by = nil
    @conversation.with_lock do
      accepted_by = @conversation.assignee if @conversation.assignee.present? && @conversation.assignee != Current.user
      ::Conversations::AssignmentService.new(conversation: @conversation, assignee_id: Current.user.id).perform unless accepted_by
    end
    return render_already_accepted(accepted_by) if accepted_by

    render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: Current.user }
  end

  private

  def render_already_accepted(assignee)
    render json: { error: I18n.t('chatclean.conversations.already_accepted', name: assignee.available_name) }, status: :conflict
  end
end
