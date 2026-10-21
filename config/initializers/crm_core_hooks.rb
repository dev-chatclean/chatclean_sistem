# Liga o CRM do ChatClean a models do Chatwoot sem editar os arquivos deles.
Rails.application.config.to_prepare do
  Contact.include(Crm::CoreContactHooks) unless Contact.include?(Crm::CoreContactHooks)
end
