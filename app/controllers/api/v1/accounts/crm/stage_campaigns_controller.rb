class Api::V1::Accounts::Crm::StageCampaignsController < Api::V1::Accounts::BaseController
  before_action :fetch_stage

  def index
    @campaigns = @stage.campaigns.includes(:created_by).order(created_at: :desc)
    @counts = delivery_counts(@campaigns)
  end

  def preview
    render json: @stage.campaigns.new(filters: filters_params).preview
  end

  def create
    @campaign = @stage.campaigns.create!(campaign_params.merge(created_by: Current.user))
    @counts = delivery_counts([@campaign])
    render :show
  end

  def cancel
    @campaign = @stage.campaigns.find(params[:id])
    @campaign.cancel_pending!
    @counts = delivery_counts([@campaign])
    render :show
  end

  private

  def fetch_stage
    pipeline = Current.account.crm_pipelines.find(params[:pipeline_id])
    authorize(pipeline, :update?)
    @stage = pipeline.stages.find(params[:stage_id])
  end

  # { campaign_id => { 'sent' => 3, 'failed' => 1, 'failure_reasons' => { 'outside_window' => 1 } } }
  def delivery_counts(campaigns)
    deliveries = Crm::DealCampaignDelivery.where(campaign: campaigns)
    counts = Hash.new { |hash, key| hash[key] = { 'failure_reasons' => {} } }
    deliveries.group(:campaign_id, :status).count.each { |(campaign_id, status), total| counts[campaign_id][status] = total }
    deliveries.failed.group(:campaign_id, :failure_reason).count.each do |(campaign_id, reason), total|
      counts[campaign_id]['failure_reasons'][reason] = total
    end
    counts
  end

  def filters_params
    params.fetch(:filters, {}).permit(:assignee_id, :stale_days)
  end

  def campaign_params
    params.require(:campaign).permit(
      :name, :message_type, :content,
      filters: [:assignee_id, :stale_days],
      template_params: [:name, :language, :category, { processed_params: { body: {} } }]
    )
  end
end
