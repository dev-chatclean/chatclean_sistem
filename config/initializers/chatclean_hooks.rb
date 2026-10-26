# Liga o atendimento no padrão ChatClean (E8) a classes do Chatwoot sem editar os arquivos delas.
Rails.application.config.to_prepare do
  {
    Api::V1::Accounts::ConversationsController => Chatclean::ConversationsControllerClosing,
    Api::V1::Accounts::BulkActionsController => Chatclean::BulkActionsControllerClosing,
    BulkActionsJob => Chatclean::BulkActionsJobClosing
  }.each { |klass, hooks| klass.prepend(hooks) unless klass <= hooks }
end
