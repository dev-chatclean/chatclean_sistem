# == Schema Information
#
# Table name: crm_deal_products
#
#  id         :bigint           not null, primary key
#  quantity   :integer          default(1), not null
#  unit_price :decimal(12, 2)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  deal_id    :bigint           not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_crm_deal_products_on_account_id  (account_id)
#  index_crm_deal_products_on_deal_id     (deal_id)
#  index_crm_deal_products_on_product_id  (product_id)
#
class Crm::DealProduct < ApplicationRecord
  self.table_name = 'crm_deal_products'

  MAX_QUANTITY = 100_000

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :deal_products
  belongs_to :product, class_name: 'Crm::Product', inverse_of: :deal_products

  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0, less_than: Crm::Deal::MAX_VALUE }
  validate :product_belongs_to_account

  before_validation :fill_from_deal_and_product, on: :create

  # The deal sums its products before they are validated, so the catalog price stands in for a missing unit price.
  def total
    (unit_price || product&.price).to_d * quantity.to_i
  end

  private

  def fill_from_deal_and_product
    self.account = deal&.account
    self.unit_price ||= product&.price
  end

  def product_belongs_to_account
    errors.add(:base, I18n.t('crm.products.errors.invalid_product')) if product && deal && product.account_id != deal.account_id
  end
end
