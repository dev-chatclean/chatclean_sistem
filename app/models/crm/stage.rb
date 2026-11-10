# == Schema Information
#
# Table name: crm_stages
#
#  id          :bigint           not null, primary key
#  color       :string(7)        not null
#  name        :string(50)       not null
#  position    :integer          not null
#  stage_type  :integer          default("custom"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_crm_stages_on_account_id                (account_id)
#  index_crm_stages_on_pipeline_id_and_position  (pipeline_id,position)
#
class Crm::Stage < ApplicationRecord
  self.table_name = 'crm_stages'

  belongs_to :account
  belongs_to :pipeline, class_name: 'Crm::Pipeline', inverse_of: :stages

  enum :stage_type, { initial: 0, custom: 1, won: 2, lost: 3 }

  validates :name, presence: true, length: { in: 2..50 }
  validates :color, format: { with: /\A#\h{6}\z/ }
  validates :position, presence: true
end
