class Api::V1::Accounts::Crm::DealActivitiesController < Api::V1::Accounts::BaseController
  before_action :fetch_deal
  before_action :fetch_activity, except: [:create]
  before_action :check_authorization

  def create
    @activity = @deal.activities.new(activity_params.except(:completed))
    @activity.assignee = Current.user unless @activity.assignee_id.present? && policy(@activity).reassign?
    @activity.save!
    render :show
  end

  def update
    authorize(@activity, :reassign?) if activity_params.key?(:assignee_id) && activity_params[:assignee_id].to_i != @activity.assignee_id
    @activity.assign_attributes(activity_params.except(:completed))
    @activity.completed_at = (activity_params[:completed] ? @activity.completed_at || Time.current : nil) if activity_params.key?(:completed)
    @activity.save!
    render :show
  end

  def destroy
    return render_could_not_create_error(I18n.t('crm.activities.errors.required_task_delete')) if @activity.required_by_stage_id

    @activity.destroy!
    head :ok
  end

  private

  def fetch_deal
    @deal = Current.account.crm_deals.find(params[:deal_id])
  end

  def fetch_activity
    @activity = @deal.activities.find(params[:id])
  end

  def check_authorization
    authorize(@activity || Crm::DealActivity)
  end

  def activity_params
    params.require(:activity).permit(:title, :activity_type, :priority, :due_at, :duration_minutes, :remind_before_minutes, :description,
                                     :recurrence, :assignee_id, :completed, checklist: [:title, :done])
  end
end
