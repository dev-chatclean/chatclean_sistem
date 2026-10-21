# Funis de venda da conta. Cada pipeline nasce com os estágios "Ganho" e "Perdido";
# a exclusão leva os estágios junto e é recusada (422) se houver qualquer deal.
class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Crm::Pipeline) }
  before_action :fetch_pipeline, only: [:show, :update, :destroy]

  def index
    @pipelines = account_pipelines.includes(:stages).order(is_default: :desc).order(Arel.sql('LOWER(crm_pipelines.name)'))
  end

  def show; end

  def create
    @pipeline = account_pipelines.create!(pipeline_params)
  end

  def update
    @pipeline.update!(pipeline_params)
  end

  def destroy
    @pipeline.destroy || raise(ActiveRecord::RecordInvalid, @pipeline)
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = account_pipelines.find(params[:id])
  end

  def account_pipelines
    ::Crm::Pipeline.where(account: Current.account)
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :description, :is_default)
  end
end
