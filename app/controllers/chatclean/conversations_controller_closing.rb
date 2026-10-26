# Fechamento com motivo obrigatório (US 16, CCV2-24), incluído no ConversationsController do Chatwoot
# pelo initializer chatclean_hooks. O "Fechar" de uma pessoa passa pelo Chatclean::ConversationCloser;
# robôs, reabrir, adiar e pendente seguem o fluxo do Chatwoot.
module Chatclean::ConversationsControllerClosing
  def toggle_status
    return super unless Current.user.is_a?(User) && closing?

    Chatclean::ConversationCloser.new(account_user: Current.account_user, reason_id: params[:closing_reason_id],
                                      sale_value: params[:sale_value]).perform(@conversation)
    @status = true
  rescue Chatclean::ConversationCloser::Error => e
    render_could_not_create_error(e.message)
  end

  private

  # Sem status, o toggle_status do Chatwoot fecha um atendimento aberto.
  def closing?
    return false if @conversation.resolved?

    params[:status].present? ? params[:status] == 'resolved' : @conversation.open?
  end
end
