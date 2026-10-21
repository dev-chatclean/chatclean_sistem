# Move para "Perdido", com o motivo "Contato bloqueado", os deals abertos de um contato bloqueado.
# Deals ganhos não mudam. Se o contato já foi desbloqueado quando o job roda, nada acontece.
class Crm::LoseBlockedContactDealsJob < ApplicationJob
  queue_as :default

  def perform(contact_id)
    contact = Contact.find_by(id: contact_id)
    return unless contact&.blocked?

    loss_reason = Crm::LossReason.for_blocked_contact!(contact.account)
    Crm::Deal.open.for_contact(contact.id).includes(stage: :pipeline).find_each do |deal|
      deal.update!(stage: deal.pipeline.stages.lost.first, loss_reason: loss_reason)
    end
  end
end
