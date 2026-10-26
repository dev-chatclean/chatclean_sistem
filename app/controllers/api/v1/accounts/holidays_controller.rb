# Feriados da conta (US 19, CCV2-27). Todos consultam; só o administrador altera.
class Api::V1::Accounts::HolidaysController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Chatclean::Holiday) }
  before_action :fetch_holiday, only: [:update, :destroy]

  def index
    render json: account_holidays.in_year(year).order(:date)
  end

  def create
    render json: account_holidays.create!(holiday_params)
  end

  def update
    @holiday.update!(holiday_params)
    render json: @holiday
  end

  def destroy
    @holiday.destroy!
    head :ok
  end

  def import_national
    ::Chatclean::Holiday.import_national!(Current.account, year)
    render json: account_holidays.in_year(year).order(:date)
  end

  private

  def year
    params.fetch(:year, Date.current.year).to_i
  end

  def fetch_holiday
    @holiday = account_holidays.find(params[:id])
  end

  def account_holidays
    ::Chatclean::Holiday.where(account: Current.account)
  end

  def holiday_params
    params.require(:holiday).permit(:date, :name, :message)
  end
end
