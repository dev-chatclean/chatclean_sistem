# Fechamento em massa com motivo (US 16, CCV2-24): o motivo e o valor são escolhidos uma vez para
# todos os atendimentos e conferidos antes de o job ser enfileirado.
module Chatclean::BulkActionsControllerClosing
  def self.prepended(base)
    base.before_action :validate_closing, only: :create, if: -> { normalized_type == 'Conversation' && closing? }
  end

  private

  def closing?
    current_user.is_a?(User) && params.dig(:fields, :status) == 'resolved'
  end

  def validate_closing
    Chatclean::ConversationCloser.new(account_user: Current.account_user, reason_id: params[:closing_reason_id],
                                      sale_value: params[:sale_value]).validate!
  rescue Chatclean::ConversationCloser::Error => e
    render_could_not_create_error(e.message)
  end

  def conversation_params
    super.merge(params.permit(:closing_reason_id, :sale_value))
  end
end
