# Horário de atendimento da conta (US 19, CCV2-27). Todos consultam; só o administrador altera.
class Api::V1::Accounts::WorkingSchedulesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Chatclean::AccountSchedule) }

  def show
    render json: schedule
  end

  def update
    schedule.update!(schedule_params)
    render json: schedule
  end

  private

  def schedule
    @schedule ||= ::Chatclean::AccountSchedule.for(Current.account)
  end

  def schedule_params
    params.require(:working_schedule).permit(:mode, :enabled, :timezone, :out_of_office_message,
                                             working_hours: ::Chatclean::AccountSchedule::DAY_ATTRS)
  end
end
