# Funis de venda da conta. Cada pipeline nasce com os estágios "Ganho" e "Perdido";
# a exclusão leva os estágios junto e é recusada (422) se houver qualquer deal.
class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Crm::Pipeline) }
  before_action :fetch_pipeline, only: [:show, :update, :destroy, :summary]

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

  # Quantidade e valor total de deals por estágio, para os cabeçalhos do Kanban.
  # Aceita o mesmo filtro assignee_id da listagem de deals (id do agente ou "none").
  def summary
    deals = ::Crm::Deal.where(crm_stage_id: @pipeline.stages.ids)
    deals = deals.assigned_to(params[:assignee_id]) if params[:assignee_id].present?
    totals = deals.group(:crm_stage_id).pluck(:crm_stage_id, Arel.sql('COUNT(*)'), Arel.sql('SUM(value)'))
                  .to_h { |stage_id, count, value| [stage_id, [count, value]] }
    @summary = @pipeline.stages.map { |stage| [stage.id, *totals.fetch(stage.id, [0, 0])] }
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
