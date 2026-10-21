# Oportunidades do CRM. O status vem do estágio: para ganhar, perder ou reabrir, mova o deal
# (crm_stage_id) para um estágio won, lost ou open do pipeline. Perder exige crm_loss_reason_id.
class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 50

  before_action -> { check_authorization(::Crm::Deal) }
  before_action :fetch_deal, only: [:show, :update]

  def index
    @deals = filtered_deals.order(created_at: :desc).page(params[:page]).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @deal = ::Crm::Deal.create!(deal_attributes.merge(account: Current.account, crm_contact: crm_contact))
  end

  def update
    @deal.update!(deal_attributes)
  end

  private

  def fetch_deal
    @deal = account_scoped(::Crm::Deal).find(params[:id])
  end

  def filtered_deals
    filters = params.slice(:crm_stage_id, :status).permit(:crm_stage_id, :status).compact_blank
    deals = account_scoped(::Crm::Deal).includes(:stage, :loss_reason, :assignee, crm_contact: :contact).where(filters.to_h)
    deals = deals.in_pipeline(params[:crm_pipeline_id]) if params[:crm_pipeline_id].present?
    deals = deals.for_contact(params[:contact_id]) if params[:contact_id].present?
    deals
  end

  def deal_params
    params.require(:deal).permit(:title, :value, :expected_close_date, :loss_details,
                                 :crm_stage_id, :crm_loss_reason_id, :assignee_id, :contact_id)
  end

  # IDs de outra conta não são encontrados e devolvem 404 (FA 3.2).
  def deal_attributes
    attributes = deal_params.slice(:title, :value, :expected_close_date, :loss_details).to_h
    attributes[:stage] = account_scoped(::Crm::Stage).find(deal_params[:crm_stage_id]) if deal_params[:crm_stage_id].present?
    attributes[:loss_reason] = find_optional(account_scoped(::Crm::LossReason), :crm_loss_reason_id) if deal_params.key?(:crm_loss_reason_id)
    attributes[:assignee] = find_optional(Current.account.users, :assignee_id) if deal_params.key?(:assignee_id)
    attributes
  end

  def crm_contact
    return if deal_params[:contact_id].blank?

    ::Crm::Contact.for_contact!(Current.account.contacts.find(deal_params[:contact_id]))
  end

  def find_optional(scope, key)
    scope.find(deal_params[key]) if deal_params[key].present?
  end

  def account_scoped(model)
    model.where(account: Current.account)
  end
end
