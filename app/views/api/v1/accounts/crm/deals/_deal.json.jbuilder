json.id deal.id
json.number deal.number
json.title deal.title
json.display_name deal.display_name
json.value deal.value.to_f
json.status deal.status
json.pipeline_id deal.pipeline_id
json.stage_id deal.stage_id
json.expected_close_date deal.expected_close_date
json.notes deal.notes
json.close_reason deal.close_reason
json.close_note deal.close_note
json.stage_entered_at deal.stage_entered_at.to_i
json.closed_at deal.closed_at&.to_i
json.created_at deal.created_at.to_i
json.contact do
  if deal.contact
    json.id deal.contact.id
    json.name deal.contact.name
    json.phone_number deal.contact.phone_number
    json.email deal.contact.email
    json.thumbnail deal.contact.avatar_url
  else
    json.nil!
  end
end
json.company do
  if deal.company
    json.id deal.company.id
    json.name deal.company.name
  else
    json.nil!
  end
end
json.assignee do
  json.id deal.assignee.id
  json.name deal.assignee.available_name
  json.thumbnail deal.assignee.avatar_url
end
