# Contatos e empresas que podem ter oportunidades do CRM (US 33).
module CrmDealable
  extend ActiveSupport::Concern

  included do
    has_many :crm_deals, class_name: 'Crm::Deal', dependent: :nullify
  end
end
