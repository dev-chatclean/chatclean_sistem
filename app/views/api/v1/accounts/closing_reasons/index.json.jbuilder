json.payload do
  json.array! @closing_reasons do |closing_reason|
    json.partial! 'api/v1/models/chatclean/closing_reason', formats: [:json], resource: closing_reason
  end
end
