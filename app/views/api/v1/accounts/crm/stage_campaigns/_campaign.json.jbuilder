campaign_counts = counts[campaign.id]
json.id campaign.id
json.stage_id campaign.stage_id
json.name campaign.name
json.status campaign.status
json.message_type campaign.message_type
json.filters campaign.filters
json.total_targets campaign.total_targets
json.created_by_name campaign.created_by.name
json.created_at campaign.created_at.to_i
json.counts do
  Crm::DealCampaignDelivery.statuses.each_key { |status| json.set! status, campaign_counts.fetch(status, 0) }
end
json.failure_reasons campaign_counts['failure_reasons']
