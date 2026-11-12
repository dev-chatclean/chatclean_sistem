class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::BaseController
  BOARD_CLOSED_WINDOW = 30.days

  before_action :fetch_deal, except: [:index, :create]
  before_action :check_authorization

  def index
    @deals = party_deals || pipeline_deals
    @deals = @deals.includes({ contact: :labels }, { conversation: :inbox }, { deal_products: :product }, :files, :company, :assignee, :stage,
                             :pipeline, :pending_activities)
  end

  def show; end

  def create
    @deal = Current.account.crm_deals.new(deal_params)
    @deal.assignee = Current.user unless @deal.assignee_id.present? && policy(@deal).reassign?
    @deal.save!
    render :show
  end

  def update
    authorize(@deal, :reassign?) if deal_params.key?(:assignee_id) && deal_params[:assignee_id].to_i != @deal.assignee_id
    @deal.assign_attributes(deal_params.except(:custom_attributes))
    @deal.merge_custom_attributes(deal_params[:custom_attributes].to_h) if deal_params.key?(:custom_attributes)
    @deal.save!
    render :show
  end

  def duplicate
    copy = @deal.slice(:stage_id, :contact_id, :company_id, :title, :value, :expected_close_date, :notes)
                .merge(deal_products_attributes: @deal.deal_products.map { |item| item.slice(:product_id, :quantity, :unit_price) })
    @deal = Current.account.crm_deals.create!(copy.merge(assignee: policy(@deal).reassign? ? @deal.assignee : Current.user))
    render :show
  end

  def destroy
    @deal.destroy!
    head :ok
  end

  private

  def pipeline_deals
    deals = Current.account.crm_pipelines.find(params.require(:pipeline_id)).deals
    deals = deals.board_visible(BOARD_CLOSED_WINDOW.ago) unless params[:view] == 'all'
    deals.order(:stage_entered_at, :id)
  end

  # The deals of a contact or a company, newest first.
  def party_deals
    party = if params[:contact_id].present?
              Current.account.contacts.find(params[:contact_id])
            elsif params[:company_id].present?
              Current.account.companies.find(params[:company_id])
            end
    party&.crm_deals&.order(created_at: :desc)
  end

  def fetch_deal
    @deal = Current.account.crm_deals.find(params[:id])
  end

  def check_authorization
    authorize(@deal || Crm::Deal)
  end

  def deal_params
    params.require(:deal).permit(:stage_id, :contact_id, :company_id, :title, :value, :expected_close_date, :notes, :assignee_id,
                                 :close_reason, :close_note,
                                 custom_attributes: {}, deal_products_attributes: [:id, :product_id, :quantity, :unit_price, :_destroy])
  end
end
