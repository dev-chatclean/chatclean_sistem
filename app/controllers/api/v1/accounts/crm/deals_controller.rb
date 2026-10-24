# Oportunidades do CRM. O status vem do estágio: para ganhar, perder ou reabrir, mova o deal
# (crm_stage_id) para um estágio won, lost ou open do pipeline. Perder exige crm_loss_reason_id.
# conversation_id registra a conversa de origem e não pode ser trocado depois. O painel da conversa
# envia conversation_display_id, o número que aparece na URL (CCV2-16).
# O atendente só vê e edita os deals em que é o responsável; só o administrador troca o
# responsável (US 27).
class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 50
  # Contato e responsável aparecem no card do Kanban com nome e avatar.
  CARD_INCLUDES = [:stage, :loss_reason, :conversation, { assignee: { avatar_attachment: :blob } },
                   { crm_contact: { contact: { avatar_attachment: :blob } } }].freeze
  # Filtros da listagem que viram scopes do Crm::Deal (assignee_id aceita "none").
  SCOPE_FILTERS = { crm_pipeline_id: :in_pipeline, contact_id: :for_contact, assignee_id: :assigned_to }.freeze

  before_action -> { check_authorization(::Crm::Deal) }
  before_action :fetch_deal, only: [:show, :update]

  def index
    @deals = filtered_deals.order(created_at: :desc).page(params[:page]).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    attributes = deal_attributes.merge(account: Current.account, crm_contact: crm_contact)
    attributes[:assignee] = Current.user unless Current.account_user.administrator?
    @deal = ::Crm::Deal.create!(attributes)
  end

  def update
    authorize(::Crm::Deal, :assign?) if deal_params.key?(:assignee_id)
    @deal.update!(deal_attributes)
  end

  private

  def fetch_deal
    @deal = visible_deals.find(params[:id])
  end

  def visible_deals
    account_scoped(::Crm::Deal).visible_to(Current.account_user)
  end

  def filtered_deals
    filters = params.slice(:crm_stage_id, :status, :conversation_id).permit(:crm_stage_id, :status, :conversation_id).compact_blank
    deals = visible_deals.includes(*CARD_INCLUDES).where(filters.to_h)
    SCOPE_FILTERS.reduce(deals) do |scope, (param, scope_name)|
      params[param].present? ? scope.public_send(scope_name, params[param]) : scope
    end
  end

  def deal_params
    params.require(:deal).permit(:title, :value, :expected_close_date, :loss_details,
                                 :crm_stage_id, :crm_loss_reason_id, :assignee_id, :contact_id, :conversation_id,
                                 :conversation_display_id)
  end

  # IDs de outra conta não são encontrados e devolvem 404 (FA 3.2).
  def deal_attributes
    attributes = deal_params.slice(:title, :value, :expected_close_date, :loss_details).to_h
    attributes[:stage] = account_scoped(::Crm::Stage).find(deal_params[:crm_stage_id]) if deal_params[:crm_stage_id].present?
    attributes.merge(optional_associations)
  end

  # Só entram quando a chave vem na requisição; valor vazio limpa a associação.
  def optional_associations
    associations = {}
    associations[:loss_reason] = find_optional(account_scoped(::Crm::LossReason), :crm_loss_reason_id) if deal_params.key?(:crm_loss_reason_id)
    associations[:assignee] = find_optional(Current.account.users, :assignee_id) if deal_params.key?(:assignee_id)
    associations[:conversation] = conversation if deal_params.key?(:conversation_id) || deal_params.key?(:conversation_display_id)
    associations
  end

  # Sem contact_id, o deal assume o contato da conversa de origem (CA 5.2).
  def crm_contact
    contact = deal_params[:contact_id].present? ? Current.account.contacts.find(deal_params[:contact_id]) : conversation&.contact
    ::Crm::Contact.for_contact!(contact) if contact
  end

  # Conversa de outra conta, ou que o usuário não enxerga pela inbox/time, responde 404 (CA 5.8).
  def conversation
    return if conversation_lookup.blank?

    @conversation ||= Current.account.conversations.find_by!(conversation_lookup).tap do |record|
      raise ActiveRecord::RecordNotFound unless ConversationPolicy.new(pundit_user, record).show?
    end
  end

  def conversation_lookup
    if deal_params[:conversation_display_id].present?
      { display_id: deal_params[:conversation_display_id] }
    elsif deal_params[:conversation_id].present?
      { id: deal_params[:conversation_id] }
    end
  end

  def find_optional(scope, key)
    scope.find(deal_params[key]) if deal_params[key].present?
  end

  def account_scoped(model)
    model.where(account: Current.account)
  end
end
