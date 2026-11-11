class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipelines = Current.account.crm_pipelines.includes(:stages).order(:created_at)
  end

  def show; end

  def create
    @pipeline = Current.account.crm_pipelines.create!(create_params)
  end

  def update
    @pipeline.update!(permitted_params)
  end

  def destroy
    return render_could_not_create_error(I18n.t('crm.pipelines.errors.default_cannot_be_deleted')) if @pipeline.is_default?
    return render_could_not_create_error(I18n.t('crm.pipelines.errors.has_deals')) if @pipeline.deals.exists?

    @pipeline.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:id])
  end

  def check_authorization
    authorize(@pipeline || Crm::Pipeline)
  end

  EDITABLE_ATTRIBUTES = [:name, :is_default, :description, :group_name, :item_label, :item_label_custom, :stale_after_days,
                         :one_card_per_contact, { card_fields: [] }].freeze

  def permitted_params
    params.require(:pipeline).permit(*EDITABLE_ATTRIBUTES)
  end

  def create_params
    params.require(:pipeline).permit(*EDITABLE_ATTRIBUTES, :pipeline_type, won_stage: [:name, :color], lost_stage: [:name, :color])
  end
end
