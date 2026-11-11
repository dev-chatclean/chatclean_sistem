json.id activity.id
json.title activity.title
json.activity_type activity.activity_type
json.priority activity.priority
json.due_at activity.due_at.to_i
json.duration_minutes activity.duration_minutes
json.remind_before_minutes activity.remind_before_minutes
json.description activity.description
json.recurrence activity.recurrence
json.checklist activity.checklist
json.completed_at activity.completed_at&.to_i
json.required_by_stage_name activity.required_by_stage&.name
json.assignee do
  json.id activity.assignee.id
  json.name activity.assignee.available_name
  json.thumbnail activity.assignee.avatar_url
end
