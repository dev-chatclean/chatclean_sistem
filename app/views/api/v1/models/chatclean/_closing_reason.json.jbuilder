json.id resource.id
json.name resource.name
json.is_active resource.is_active
json.closing_message resource.closing_message
json.ask_sale_value resource.ask_sale_value
json.team_ids resource.teams.map(&:id)
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
