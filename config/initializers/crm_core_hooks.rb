# Liga o CRM do ChatClean a models do Chatwoot sem editar os arquivos deles. O on_load aplica o gancho
# quando o Contact carrega, sem forçar o carregamento antes das traduções (as mensagens de validação
# do Contact são traduzidas ao carregar a classe).
Rails.autoloaders.main.on_load('Contact') { |klass, _path| klass.include(Crm::CoreContactHooks) }
