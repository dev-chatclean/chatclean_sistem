json.id resource.id
json.title resource.title
json.value resource.value.to_s
json.currency resource.currency
json.status resource.status
json.expected_close_date resource.expected_close_date
json.crm_stage_id resource.crm_stage_id
json.crm_pipeline_id resource.stage.crm_pipeline_id
json.crm_contact_id resource.crm_contact_id
json.contact_id resource.crm_contact.contact_id
json.assignee_id resource.assignee_id
json.contact do
  json.id resource.crm_contact.contact.id
  json.name resource.crm_contact.contact.name
  json.thumbnail resource.crm_contact.contact.avatar_url
  json.blocked resource.crm_contact.contact.blocked
end
json.assignee do
  if resource.assignee
    json.id resource.assignee.id
    json.name resource.assignee.available_name
    json.avatar_url resource.assignee.avatar_url
  else
    json.nil!
  end
end
json.conversation_id resource.conversation_id
# A rota da conversa no painel usa o número de exibição, não o id.
json.conversation_display_id resource.conversation&.display_id
json.loss_reason do
  if resource.loss_reason
    json.id resource.loss_reason.id
    json.name resource.loss_reason.name
  else
    json.nil!
  end
end
json.loss_details resource.loss_details
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
