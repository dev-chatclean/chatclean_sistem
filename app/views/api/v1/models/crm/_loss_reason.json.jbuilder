json.id resource.id
json.name resource.name
json.description resource.description
json.is_active resource.is_active
# Motivo criado pelo sistema (ex.: "Contato bloqueado"): pode ser renomeado, mas não desativado.
json.is_system resource.system_key.present?
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
