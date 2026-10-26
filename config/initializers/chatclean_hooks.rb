# Liga o atendimento no padrão ChatClean (E8) a classes do Chatwoot sem editar os arquivos delas.
# O on_load aplica cada gancho quando a classe carrega (inclusive depois de um reload), sem forçar o
# carregamento cedo: classes que traduzem mensagens ao carregar precisam das traduções já prontas.
{
  'Api::V1::Accounts::ConversationsController' => 'Chatclean::ConversationsControllerClosing',
  'Api::V1::Accounts::BulkActionsController' => 'Chatclean::BulkActionsControllerClosing',
  'BulkActionsJob' => 'Chatclean::BulkActionsJobClosing',
  'Api::V1::Accounts::CannedResponsesController' => 'Chatclean::CannedResponsesControllerScope'
}.each do |class_name, hooks|
  Rails.autoloaders.main.on_load(class_name) { |klass, _path| klass.prepend(hooks.constantize) }
end

{
  'CannedResponse' => 'Chatclean::CannedResponseScope',
  'TeamMember' => 'Chatclean::TeamMemberCannedCache',
  'Team' => 'Chatclean::TeamCannedCache'
}.each do |class_name, hooks|
  Rails.autoloaders.main.on_load(class_name) { |klass, _path| klass.include(hooks.constantize) }
end
