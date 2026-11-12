class Crm::CampaignDeliveryJob < ApplicationJob
  queue_as :medium

  def perform(delivery_id)
    delivery = Crm::DealCampaignDelivery.find_by(id: delivery_id)
    return unless delivery&.scheduled?

    send_delivery(delivery)
    delivery.campaign.complete_if_finished!
  end

  private

  def send_delivery(delivery)
    campaign = delivery.campaign
    deal = delivery.deal
    return delivery.finish!(:canceled, failure_reason: 'stage_changed') if deal.stage_id != campaign.stage_id

    sender = Crm::ClientMessageService.new(deal: deal, message_type: campaign.message_type, content: campaign.content,
                                           template_params: campaign.template_params)
    message = sender.perform
    message ? delivery.finish!(:sent, message: message) : delivery.finish!(:failed, failure_reason: sender.failure_reason)
  end
end
