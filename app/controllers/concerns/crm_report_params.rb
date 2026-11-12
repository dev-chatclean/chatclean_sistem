# Request rules shared by the CRM reports: administrators only, a period of 7, 30 or 90 days, a known time zone
# and well-formed filters. Each controller lists its own ID_PARAMS, NUMBER_PARAMS, OPTION_PARAMS, DATE_PARAMS and FILTER_PARAMS.
module CrmReportParams
  extend ActiveSupport::Concern

  PERIODS = [7, 30, 90].freeze
  ID_PATTERN = /\A\d+\z/
  NUMBER_PATTERN = /\A\d+(\.\d+)?\z/

  included do
    before_action :check_admin_authorization?
    before_action :validate_params
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

    filter_error
  end

  def filter_error
    return 'invalid_text' unless given(self.class::FILTER_PARAMS).all?(String)
    return 'invalid_number' unless numbers_valid?
    return 'invalid_option' unless options_valid?

    'invalid_date' unless given(self.class::DATE_PARAMS).all? { |value| iso_date?(value) }
  end

  def numbers_valid?
    given(self.class::ID_PARAMS).all?(ID_PATTERN) && given(self.class::NUMBER_PARAMS).all?(NUMBER_PATTERN)
  end

  def options_valid?
    self.class::OPTION_PARAMS.all? { |key, allowed| params[key].nil? || allowed.include?(params[key]) }
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

  def date_range(prefix)
    from = params["#{prefix}_from"]
    to = params["#{prefix}_to"]
    range(from && time_zone.parse(from).beginning_of_day, to && time_zone.parse(to).end_of_day)
  end

  def range(from, to)
    from..to if from || to
  end
end
