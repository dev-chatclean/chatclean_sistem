json.payload @impulses do |impulse|
  json.partial! 'api/v1/accounts/crm/impulses/impulse', impulse: impulse
end
