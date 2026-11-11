# Contatos e empresas que podem ter oportunidades do CRM (US 33).
module CrmDealable
  extend ActiveSupport::Concern

  included do
    has_many :crm_deals, class_name: 'Crm::Deal', dependent: :nullify
  end

  # Deleting a contact with deals is blocked where people delete contacts (single and bulk), not here:
  # account deletion still removes every contact.
  def crm_deals_deletion_error
    I18n.t('crm.contacts.errors.has_deals', count: crm_deals.count)
  end
end
