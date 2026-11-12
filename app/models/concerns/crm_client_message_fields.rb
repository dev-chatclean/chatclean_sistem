# The message sent to the deal's contact by an impulse step or a stage campaign: free text or an approved WhatsApp template.
module CrmClientMessageFields
  extend ActiveSupport::Concern

  MESSAGE_TYPES = %w[text template].freeze

  included do
    validates :message_type, inclusion: { in: MESSAGE_TYPES }
    validates :content, presence: true, length: { maximum: 4096 }, if: :text?
    validate :template_chosen, unless: :text?
  end

  def text?
    message_type == 'text'
  end

  private

  def template_chosen
    return if template_params['name'].present? && template_params['language'].present?

    errors.add(:base, I18n.t('crm.client_message.errors.template_required'))
  end
end
