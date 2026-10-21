json.payload do
  json.partial! 'api/v1/models/crm/deal', formats: [:json], resource: @deal
end
