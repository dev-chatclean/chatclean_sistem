json.payload do
  json.array! @deals do |deal|
    json.partial! 'api/v1/models/crm/deal', formats: [:json], resource: deal
  end
end
json.meta do
  json.total_count @deals.total_count
  json.page @deals.current_page
end
