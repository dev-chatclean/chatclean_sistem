# Fecha cada atendimento do lote pelo Chatclean::ConversationCloser (US 16, CCV2-24), incluído no
# BulkActionsJob do Chatwoot pelo initializer chatclean_hooks. Os demais campos seguem o fluxo original.
module Chatclean::BulkActionsJobClosing
  def bulk_conversation_update
    return super unless @user.is_a?(User) && @params.dig(:fields, :status) == 'resolved'

    closer = Chatclean::ConversationCloser.new(account_user: @account.account_users.find_by!(user: @user),
                                               reason_id: @params[:closing_reason_id], sale_value: @params[:sale_value])
    records.reject(&:resolved?).each { |conversation| closer.perform(conversation) }
    @params[:fields] = @params[:fields].except(:status)
    super
  end
end
