json.payload do
  json.array! @summary do |stage_id, deals_count, total_value|
    json.crm_stage_id stage_id
    json.deals_count deals_count
    json.total_value total_value.to_s
  end
end
