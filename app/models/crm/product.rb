# == Schema Information
#
# Table name: crm_products
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string(120)      not null
#  price       :decimal(12, 2)   default(0.0), not null
#  sku         :string(60)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_products_on_account_id  (account_id)
#
class Crm::Product < ApplicationRecord
  self.table_name = 'crm_products'

  belongs_to :account
  has_many :deal_products, class_name: 'Crm::DealProduct', inverse_of: :product, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 120 }
  validates :price, numericality: { greater_than_or_equal_to: 0, less_than: Crm::Deal::MAX_VALUE }
  validates :sku, length: { maximum: 60 }

  scope :active, -> { where(active: true) }
end
