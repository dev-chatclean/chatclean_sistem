json.payload do
  json.array! @loss_reasons do |loss_reason|
    json.partial! 'api/v1/models/crm/loss_reason', formats: [:json], resource: loss_reason
  end
end
