# Estágios de um pipeline. Os criados aqui são abertos e entram antes de "Ganho" e "Perdido",
# que só podem ser renomeados. A reordenação recebe só os estágios abertos.
class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Crm::Stage) }
  before_action :fetch_pipeline
  before_action :fetch_stage, only: [:update, :destroy]

  def index
    @stages = @pipeline.stages
  end

  def create
    @stage = @pipeline.stages.create!(stage_params.merge(account: Current.account))
  end

  def update
    @stage.update!(stage_params)
  end

  def destroy
    @stage.destroy || raise(ActiveRecord::RecordInvalid, @stage)
    head :ok
  end

  def reorder
    @pipeline.reorder_open_stages!(params.require(:stage_ids))
    @stages = @pipeline.stages
    render :index
  end

  private

  def fetch_pipeline
    @pipeline = ::Crm::Pipeline.where(account: Current.account).find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :probability, :status)
  end
end
