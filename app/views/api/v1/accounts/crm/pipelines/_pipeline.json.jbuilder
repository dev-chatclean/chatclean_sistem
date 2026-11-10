json.id pipeline.id
json.name pipeline.name
json.is_default pipeline.is_default
json.description pipeline.description
json.group_name pipeline.group_name
json.pipeline_type pipeline.pipeline_type
json.item_label pipeline.item_label
json.item_label_custom pipeline.item_label_custom
json.stale_after_days pipeline.stale_after_days
json.one_card_per_contact pipeline.one_card_per_contact
json.card_fields pipeline.card_fields
json.stages pipeline.stages do |stage|
  json.id stage.id
  json.name stage.name
  json.stage_type stage.stage_type
  json.color stage.color
  json.position stage.position
  json.stale_after_days stage.stale_after_days
  json.requirements stage.requirements
end
