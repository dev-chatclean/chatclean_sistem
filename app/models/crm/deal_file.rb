class Crm::DealFile < ApplicationRecord
  include Rails.application.routes.url_helpers

  self.table_name = 'crm_deal_files'

  CATEGORIES = %w[proposal contract client_document receipt other].freeze
  ACCEPTABLE_FILE_TYPES = %w[
    application/pdf text/plain text/csv application/zip
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    image/png image/jpeg image/webp
  ].freeze

  belongs_to :account
  belongs_to :deal, class_name: 'Crm::Deal', inverse_of: :files
  belongs_to :uploaded_by, class_name: 'User'
  has_one_attached :file

  validates :category, inclusion: { in: CATEGORIES }
  validate :acceptable_file

  before_validation :inherit_account, on: :create
  after_create { record_deal_event('file_added') }
  after_destroy { record_deal_event('file_removed') }

  def file_url
    url_for(file)
  end

  private

  def inherit_account
    self.account = deal&.account
  end

  def acceptable_file
    return errors.add(:base, I18n.t('crm.deal_files.errors.missing')) unless file.attached?
    return errors.add(:base, I18n.t('crm.deal_files.errors.invalid_type')) unless ACCEPTABLE_FILE_TYPES.include?(file.blob.content_type)

    limit_mb = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', 40).to_i
    errors.add(:base, I18n.t('crm.deal_files.errors.too_large', limit: limit_mb)) if file.blob.byte_size > limit_mb.megabytes
  end

  def record_deal_event(event_type)
    deal.events.create!(account: account, user: Current.user, event_type: event_type,
                        data: { 'file' => file.filename.to_s, 'category' => category })
  end
end
