# Contatos arquivados (US 33): saem das listas e buscas, mas os negócios continuam contando.
module ContactArchivable
  extend ActiveSupport::Concern

  included do
    scope :archive_filter, ->(archived) { archived ? where.not(archived_at: nil) : where(archived_at: nil) }
  end
end
