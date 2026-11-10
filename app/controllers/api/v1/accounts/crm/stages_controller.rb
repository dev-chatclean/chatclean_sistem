class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :fetch_stage, only: [:update, :destroy]

  def create
    @pipeline.add_custom_stage!(stage_params, after_stage_id: params[:after_stage_id])
    render_pipeline
  end

  def update
    @stage.update!(stage_params)
    render_pipeline
  end

  def destroy
    @pipeline.remove_custom_stage!(@stage, transfer_to_stage_id: params[:transfer_to_stage_id])
    render_pipeline
  end

  def reorder
    @pipeline.reorder_open_stages!(params.require(:stage_ids))
    render_pipeline
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:pipeline_id])
    authorize(@pipeline, :update?)
  end

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def render_pipeline
    @pipeline.stages.reset
    render 'api/v1/accounts/crm/pipelines/show'
  end

  def stage_params
    params.require(:stage).permit(
      :name, :color, :stale_after_days,
      requirements: [:require_owner, :require_expected_close_date, :require_positive_value, :require_product, :require_document,
                     { required_custom_fields: [], required_tasks: [], apply_labels: [] }]
    )
  end
end
