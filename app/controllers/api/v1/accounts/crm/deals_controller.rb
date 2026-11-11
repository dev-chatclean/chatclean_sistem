class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::BaseController
  BOARD_CLOSED_WINDOW = 30.days

  before_action :fetch_deal, except: [:index, :create]
  before_action :check_authorization

  def index
    @deals = params[:contact_id].present? ? contact_deals : pipeline_deals
    @deals = @deals.includes(:contact, :company, :assignee, :stage, :pipeline)
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
    @deal.update!(deal_params)
    render :show
  end

  def duplicate
    copy = @deal.slice(:stage_id, :contact_id, :company_id, :title, :value, :expected_close_date, :notes)
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

  def contact_deals
    Current.account.contacts.find(params[:contact_id]).crm_deals.order(created_at: :desc)
  end

  def fetch_deal
    @deal = Current.account.crm_deals.find(params[:id])
  end

  def check_authorization
    authorize(@deal || Crm::Deal)
  end

  def deal_params
    params.require(:deal).permit(:stage_id, :contact_id, :company_id, :title, :value, :expected_close_date, :notes, :assignee_id,
                                 :close_reason, :close_note)
  end
end
