class Crm::DealCampaignDelivery < ApplicationRecord
  self.table_name = 'crm_deal_campaign_deliveries'

  belongs_to :account
  belongs_to :campaign, class_name: 'Crm::StageCampaign', inverse_of: :deliveries
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :campaign_deliveries
  belongs_to :message, optional: true

  enum :status, { scheduled: 0, sent: 1, canceled: 2, failed: 3 }

  # A deleted deal takes its pending send with it; the campaign ends when nothing is left to send.
  after_destroy_commit -> { campaign.complete_if_finished! }, if: :scheduled?

  def finish!(status, failure_reason: nil, message: nil)
    update!(status: status, failure_reason: failure_reason, message: message, executed_at: Time.current)
    deal.events.create!(account: account, event_type: "campaign_#{status}", data: { 'campaign' => campaign.name, 'reason' => failure_reason }.compact)
  end
end
