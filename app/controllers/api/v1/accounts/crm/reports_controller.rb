class Api::V1::Accounts::Crm::ReportsController < Api::V1::Accounts::BaseController
  PERIODS = [7, 30, 90].freeze
  ID_PARAMS = %w[pipeline_id stage_id assignee_id inbox_id].freeze
  NUMBER_PARAMS = %w[value_min value_max].freeze
  TEXT_PARAMS = %w[contact company title].freeze
  DATE_PREFIXES = %w[created closed stage_entered].freeze
  DATE_PARAMS = DATE_PREFIXES.flat_map { |prefix| ["#{prefix}_from", "#{prefix}_to"] }.freeze
  FILTER_PARAMS = (ID_PARAMS + NUMBER_PARAMS + TEXT_PARAMS + DATE_PARAMS).freeze
  ID_PATTERN = /\A\d+\z/
  NUMBER_PATTERN = /\A\d+(\.\d+)?\z/

  before_action :check_admin_authorization?
  before_action :validate_params

  def sales
    render json: Crm::SalesReport.new(account: Current.account, period: params[:period].to_i, time_zone: time_zone, filters: filters).build
  end

  private

  def time_zone
    ActiveSupport::TimeZone[params[:time_zone].to_s]
  end

  def validate_params
    error = params_error
    render_could_not_create_error(I18n.t("crm.reports.errors.#{error}")) if error
  end

  def params_error
    return 'invalid_period' if PERIODS.exclude?(params[:period].to_i)
    return 'invalid_time_zone' if time_zone.nil?
    return 'invalid_text' unless given(FILTER_PARAMS).all?(String)
    return 'invalid_number' unless numbers_valid?

    'invalid_date' unless given(DATE_PARAMS).all? { |value| iso_date?(value) }
  end

  def numbers_valid?
    given(ID_PARAMS).all?(ID_PATTERN) && given(NUMBER_PARAMS).all?(NUMBER_PATTERN)
  end

  def given(keys)
    keys.filter_map { |key| params[key] }
  end

  def iso_date?(value)
    Date.iso8601(value)
    true
  rescue Date::Error
    false
  end

  def filters
    params.permit(*ID_PARAMS, *TEXT_PARAMS).to_h.symbolize_keys.compact_blank.merge(
      value: range(params[:value_min]&.to_d, params[:value_max]&.to_d),
      created_at: date_range('created'), closed_at: date_range('closed'), stage_entered_at: date_range('stage_entered')
    ).compact
  end

  def date_range(prefix)
    from = params["#{prefix}_from"]
    to = params["#{prefix}_to"]
    range(from && time_zone.parse(from).beginning_of_day, to && time_zone.parse(to).end_of_day)
  end

  def range(from, to)
    from..to if from || to
  end
end
