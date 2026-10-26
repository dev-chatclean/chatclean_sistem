# Base dos models do atendimento no padrão ChatClean (E8): Chatclean::ClosingReason usa a tabela
# chatclean_closing_reasons, e assim por diante.
class Chatclean::ApplicationRecord < ApplicationRecord
  self.abstract_class = true
  self.table_name_prefix = 'chatclean_'
end
