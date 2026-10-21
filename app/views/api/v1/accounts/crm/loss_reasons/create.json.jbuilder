json.payload do
  json.partial! 'api/v1/models/crm/loss_reason', formats: [:json], resource: @loss_reason
end
