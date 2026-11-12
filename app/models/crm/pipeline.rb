# == Schema Information
#
# Table name: crm_pipelines
#
#  id         :bigint           not null, primary key
#  is_default :boolean          default(FALSE), not null
#  name       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_crm_pipelines_on_account_id          (account_id)
#  index_crm_pipelines_on_account_id_default  (account_id) UNIQUE WHERE is_default
#
class Crm::Pipeline < ApplicationRecord
  self.table_name = 'crm_pipelines'

  REQUIRED_STAGES = [
    { stage_type: :initial, color: '#1F93FF' },
    { stage_type: :won, color: '#44CE4B' },
    { stage_type: :lost, color: '#E0484E' }
  ].freeze

  ITEM_LABELS = %w[deal client case process custom].freeze
  CARD_FIELDS = %w[expected_close_date products next_task contact_labels origin attachments].freeze
  MAX_CARD_FIELDS = 4

  attr_accessor :won_stage, :lost_stage

  enum :pipeline_type, { sales: 0, management: 1 }

  belongs_to :account
  has_many :deals, class_name: 'Crm::Deal', dependent: :destroy
  has_many :stages, -> { order(:position) }, class_name: 'Crm::Stage', inverse_of: :pipeline, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :item_label, inclusion: { in: ITEM_LABELS }
  validates :item_label_custom, presence: true, length: { maximum: 30 }, if: -> { item_label == 'custom' }
  validates :stale_after_days, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }
  validate :card_fields_allowed
  validate :default_cannot_be_unset, on: :update

  before_validation :become_default_if_first, :build_required_stages, on: :create
  before_save :unset_other_defaults, if: -> { is_default? && will_save_change_to_is_default? }

  def add_custom_stage!(attributes, after_stage_id: nil)
    ordered = stages.to_a
    closing_index = ordered.index(&:closing?)
    anchor_index = ordered.index { |stage| stage.id == after_stage_id.to_i } if after_stage_id.present?
    insert_at = anchor_index && anchor_index < closing_index ? anchor_index + 1 : closing_index

    stage = stages.build(attributes.merge(account: account, stage_type: :custom, position: insert_at))
    transaction do
      stage.save!
      renumber_stages!(ordered.insert(insert_at, stage))
    end
    stage
  end

  def remove_custom_stage!(stage, transfer_to_stage_id: nil)
    raise_invalid!(I18n.t('crm.stages.errors.system_stage_delete')) unless stage.custom?
    target = transfer_target(stage, transfer_to_stage_id)
    deals_count = deals.where(stage: stage).count
    raise_invalid!(I18n.t('crm.stages.errors.transfer_required', count: deals_count)) if deals_count.positive? && target.nil?

    transaction do
      # The tasks the removed stage required become ordinary tasks.
      Crm::DealActivity.where(required_by_stage: stage).update_all(required_by_stage_id: nil) # rubocop:disable Rails/SkipsModelValidations
      deals.where(stage: stage).find_each { |deal| deal.update!(stage: target) }
      stage.destroy!
      renumber_stages!(stages.reload.to_a)
    end
  end

  def reorder_open_stages!(stage_ids)
    open_stages = stages.where(stage_type: %i[initial custom]).index_by(&:id)
    ordered_ids = stage_ids.map(&:to_i)
    unless ordered_ids.sort == open_stages.keys.sort && open_stages[ordered_ids.first]&.initial?
      raise_invalid!(I18n.t('crm.stages.errors.invalid_order'))
    end

    transaction { renumber_stages!(open_stages.values_at(*ordered_ids) + stages.where(stage_type: %i[won lost]).to_a) }
  end

  private

  def transfer_target(stage, transfer_to_stage_id)
    return if transfer_to_stage_id.blank?

    stages.where(stage_type: %i[initial custom]).where.not(id: stage.id).find_by(id: transfer_to_stage_id) ||
      raise_invalid!(I18n.t('crm.stages.errors.invalid_transfer_stage'))
  end

  def raise_invalid!(message)
    errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, self
  end

  def renumber_stages!(ordered_stages)
    ordered_stages.each_with_index { |stage, position| stage.update!(position: position) if stage.position != position }
  end

  def become_default_if_first
    self.is_default = true unless account.crm_pipelines.exists?
  end

  def build_required_stages
    I18n.with_locale(account.locale) do
      REQUIRED_STAGES.each_with_index do |stage, position|
        custom = { won: won_stage, lost: lost_stage }[stage[:stage_type]].to_h.compact_blank
        stages.build({ account: account, position: position, name: I18n.t("crm.stages.defaults.#{stage[:stage_type]}") }.merge(stage, custom))
      end
    end
  end

  def unset_other_defaults
    account.crm_pipelines.where(is_default: true).where.not(id: id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def card_fields_allowed
    return if card_fields.is_a?(Array) && card_fields.size <= MAX_CARD_FIELDS && (card_fields - CARD_FIELDS).empty?

    errors.add(:base, I18n.t('crm.pipelines.errors.invalid_card_fields', max: MAX_CARD_FIELDS))
  end

  def default_cannot_be_unset
    return unless is_default_changed?(from: true, to: false)

    errors.add(:base, I18n.t('crm.pipelines.errors.default_cannot_be_unset'))
  end
end
