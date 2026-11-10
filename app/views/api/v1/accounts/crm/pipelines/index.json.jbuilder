json.payload do
  json.array! @pipelines, partial: 'api/v1/accounts/crm/pipelines/pipeline', as: :pipeline
end
