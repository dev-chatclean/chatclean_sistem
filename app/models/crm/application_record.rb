# Base dos models do CRM do ChatClean: Crm::Deal usa a tabela crm_deals, Crm::Pipeline usa crm_pipelines.
# O namespace Crm:: é compartilhado com a integração LeadSquared do Chatwoot (app/services/crm), que usa
# definições compactas; por isso Contact, Conversation etc. continuam resolvendo para os models do core.
class Crm::ApplicationRecord < ApplicationRecord
  self.abstract_class = true
  self.table_name_prefix = 'crm_'
end
