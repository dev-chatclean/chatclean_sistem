class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline

  def update
    @pipeline.stages.find(params[:id]).update!(params.require(:stage).permit(:name, :color))
    render 'api/v1/accounts/crm/pipelines/show'
  end

  def reorder
    @pipeline.reorder_open_stages!(params.require(:stage_ids))
    render 'api/v1/accounts/crm/pipelines/show'
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:pipeline_id])
    authorize(@pipeline, :update?)
  end
end
