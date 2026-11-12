json.payload do
  json.array! @products, partial: 'api/v1/accounts/crm/products/product', as: :product
end
