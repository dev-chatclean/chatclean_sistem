json.payload do
  json.partial! 'api/v1/models/chatclean/closing_reason', formats: [:json], resource: @closing_reason
end
