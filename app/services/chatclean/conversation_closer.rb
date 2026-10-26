# Fecha um atendimento a pedido de uma pessoa, com motivo obrigatório (US 16, CCV2-24):
# envia a mensagem de fechamento do motivo, fecha, registra o fechamento e, quando o motivo
# pede o valor da venda, leva a venda para o funil do CRM.
#
# Os fechamentos automáticos (robôs, automações, inatividade) não passam por aqui.
class Chatclean::ConversationCloser
  class Error < StandardError; end

  attr_reader :reason, :sale_value

  def initialize(account_user:, reason_id:, sale_value: nil)
    @account_user = account_user
    @reason = Chatclean::ClosingReason.where(account_id: account_user.account_id)
                                      .available_to(account_user).active.find_by(id: reason_id)
    @sale_value = BigDecimal(sale_value.to_s, exception: false) if sale_value.present?
  end

  # Confere motivo e valor antes de fechar, para devolver 422 sem mexer no atendimento.
  def validate!
    raise Error, I18n.t('chatclean.closing.reason_required') if reason.nil?
    raise Error, I18n.t('chatclean.closing.invalid_sale_value') if reason.ask_sale_value? && (sale_value.nil? || sale_value.negative?)
  end

  def perform(conversation)
    validate!
    ActiveRecord::Base.transaction do
      send_closing_message(conversation)
      conversation.update!(status: :resolved)
      Chatclean::ConversationClosure.create!(account_id: conversation.account_id, conversation: conversation, closing_reason: reason,
                                             user: @account_user.user, sale_value: (sale_value if reason.ask_sale_value?),
                                             crm_deal: register_sale(conversation))
    end
  end

  private

  def send_closing_message(conversation)
    return if reason.closing_message.blank?

    Messages::MessageBuilder.new(@account_user.user, conversation, { content: reason.closing_message }).perform
  end

  # Regra aprovada pelo PO: o deal de origem do atendimento ou o único deal aberto do contato vira
  # "Ganho" com o valor da venda; sem nenhum dos dois, nasce um deal "Ganho" no funil padrão, com
  # quem fechou como responsável. Conta sem funil padrão não usa o CRM e fica só com o registro.
  def register_sale(conversation)
    return unless reason.ask_sale_value?

    crm_contact = Crm::Contact.for_contact!(conversation.contact)
    open_deals = crm_contact.deals.open
    deal = open_deals.where(conversation: conversation).order(:created_at).last || (open_deals.one? ? open_deals.first : nil)
    return win(deal, deal.pipeline) if deal

    pipeline = Crm::Pipeline.find_by(account_id: conversation.account_id, is_default: true)
    return unless pipeline

    deal = Crm::Deal.new(account_id: conversation.account_id, crm_contact: crm_contact, conversation: conversation,
                         assignee: @account_user.user, title: deal_title(conversation))
    win(deal, pipeline)
  end

  def win(deal, pipeline)
    deal.update!(stage: pipeline.stages.find_by!(status: :won), value: sale_value)
    deal
  end

  def deal_title(conversation)
    I18n.with_locale(conversation.account.locale) do
      I18n.t('chatclean.closing.deal_title', reason: reason.name, id: conversation.display_id)
    end
  end
end
