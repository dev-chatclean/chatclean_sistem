json.payload do
  json.array! @deals, partial: 'api/v1/accounts/crm/deals/deal', as: :deal
end
