json.partial! 'api/v1/accounts/crm/deals/deal', deal: @deal
json.events @deal.events.includes(:user) do |event|
  json.id event.id
  json.event_type event.event_type
  json.user_name event.user&.available_name
  json.from_stage_name event.data['from_stage_name']
  json.to_stage_name event.data['to_stage_name']
  json.data event.data.except('from_stage_name', 'to_stage_name')
  json.created_at event.created_at.to_i
end
json.journey @deal.journey do |entry|
  json.stage_name entry[:stage_name]
  json.entered_at entry[:entered_at].to_i
  json.left_at entry[:left_at]&.to_i
end
json.activities @deal.activities.includes(:assignee, :required_by_stage) do |activity|
  json.partial! 'api/v1/accounts/crm/deal_activities/activity', activity: activity
end
json.files @deal.files.includes(:uploaded_by, file_attachment: :blob) do |deal_file|
  json.partial! 'api/v1/accounts/crm/deal_files/deal_file', deal_file: deal_file
end
