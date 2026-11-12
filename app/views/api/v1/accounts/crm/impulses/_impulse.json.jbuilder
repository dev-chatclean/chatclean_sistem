json.id impulse.id
json.stage_id impulse.stage_id
json.name impulse.name
json.active impulse.active
json.stop_on_reply impulse.stop_on_reply
json.steps impulse.steps do |step|
  json.id step.id
  json.position step.position
  json.delay_minutes step.delay_minutes
  json.message_type step.message_type
  json.content step.content
  json.template_params step.template_params
end
