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
