class Api::V1::Accounts::Crm::ReportsController < Api::V1::Accounts::BaseController
  include CrmReportParams

  ID_PARAMS = %w[pipeline_id stage_id assignee_id inbox_id].freeze
  NUMBER_PARAMS = %w[value_min value_max].freeze
  TEXT_PARAMS = %w[contact company title].freeze
  OPTION_PARAMS = {}.freeze
  DATE_PARAMS = %w[created closed stage_entered].flat_map { |prefix| ["#{prefix}_from", "#{prefix}_to"] }.freeze
  FILTER_PARAMS = (ID_PARAMS + NUMBER_PARAMS + TEXT_PARAMS + DATE_PARAMS).freeze

  def sales
    render json: Crm::SalesReport.new(account: Current.account, period: params[:period].to_i, time_zone: time_zone, filters: filters).build
  end

  private

  def filters
    params.permit(*ID_PARAMS, *TEXT_PARAMS).to_h.symbolize_keys.compact_blank.merge(
      value: range(params[:value_min]&.to_d, params[:value_max]&.to_d),
      created_at: date_range('created'), closed_at: date_range('closed'), stage_entered_at: date_range('stage_entered')
    ).compact
  end
end
