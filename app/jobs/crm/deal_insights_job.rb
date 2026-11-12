# Recalculates temperature and next step of an open deal. After a message it waits for the contact to stop writing:
# a later message from the same contact skips this run, since that message scheduled its own.
class Crm::DealInsightsJob < ApplicationJob
  queue_as :low

  def perform(deal_id, message_id = nil)
    deal = Crm::Deal.open.find_by(id: deal_id)
    return unless deal
    return if message_id && Message.incoming.exists?(sender: deal.contact, id: (message_id + 1)..)

    Crm::DealInsightsService.new(deal: deal).perform
  end
end
