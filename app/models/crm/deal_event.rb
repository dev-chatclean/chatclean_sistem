class Crm::DealEvent < ApplicationRecord
  self.table_name = 'crm_deal_events'

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :events
  belongs_to :user, optional: true
  belongs_to :from_stage, class_name: 'Crm::Stage', optional: true
  belongs_to :to_stage, class_name: 'Crm::Stage', optional: true

  validates :event_type, presence: true
end
