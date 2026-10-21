json.payload do
  json.partial! 'api/v1/models/crm/stage', formats: [:json], resource: @stage
end
