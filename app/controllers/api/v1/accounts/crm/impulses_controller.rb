class Api::V1::Accounts::Crm::ImpulsesController < Api::V1::Accounts::BaseController
  before_action :fetch_stage
  before_action :fetch_impulse, only: [:update, :destroy]

  def index
    @impulses = @stage.impulses.includes(:steps)
  end

  def create
    @impulse = @stage.impulses.create!(impulse_params)
    render :show
  end

  def update
    @impulse.update!(impulse_params)
    render :show
  end

  def destroy
    @impulse.destroy!
    head :ok
  end

  private

  def fetch_stage
    pipeline = Current.account.crm_pipelines.find(params[:pipeline_id])
    authorize(pipeline, :update?)
    @stage = pipeline.stages.find(params[:stage_id])
  end

  def fetch_impulse
    @impulse = @stage.impulses.find(params[:id])
  end

  def impulse_params
    params.require(:impulse).permit(
      :name, :active, :stop_on_reply,
      steps_attributes: [:id, :_destroy, :delay_minutes, :message_type, :content,
                         { template_params: [:name, :language, :category, { processed_params: { body: {} } }] }]
    )
  end
end
