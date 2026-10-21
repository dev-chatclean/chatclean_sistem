# Comportamento do CRM no Contact do Chatwoot, incluído por config/initializers/crm_core_hooks.rb
# para não editar o model do core. Bloquear um contato perde os deals abertos dele (CCV2-15).
module Crm::CoreContactHooks
  extend ActiveSupport::Concern

  included do
    after_update_commit :lose_open_crm_deals, if: -> { saved_change_to_blocked? && blocked? }
  end

  private

  def lose_open_crm_deals
    Crm::LoseBlockedContactDealsJob.perform_later(id)
  end
end
