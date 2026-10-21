json.payload do
  json.partial! 'api/v1/models/crm/pipeline', formats: [:json], resource: @pipeline
end
