json.id pipeline.id
json.name pipeline.name
json.is_default pipeline.is_default
json.stages pipeline.stages do |stage|
  json.id stage.id
  json.name stage.name
  json.stage_type stage.stage_type
  json.color stage.color
  json.position stage.position
end
