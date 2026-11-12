class Api::V1::Accounts::Crm::OverviewReportsController < Api::V1::Accounts::BaseController
  include CrmReportParams

  ID_PARAMS = %w[team_id inbox_id assignee_id].freeze
  NUMBER_PARAMS = [].freeze
  TEXT_PARAMS = %w[contact_label].freeze
  OPTION_PARAMS = { 'status' => Conversation.statuses.keys, 'contact_type' => Contact.contact_types.keys, 'unread' => %w[true] }.freeze
  DATE_PARAMS = %w[created last_activity].flat_map { |prefix| ["#{prefix}_from", "#{prefix}_to"] }.freeze
  FILTER_PARAMS = (ID_PARAMS + TEXT_PARAMS + OPTION_PARAMS.keys + DATE_PARAMS).freeze

  def show
    render json: Crm::OverviewReport.new(account: Current.account, period: params[:period].to_i, time_zone: time_zone, filters: filters).build
  end

  private

  def filters
    params.permit(*ID_PARAMS, *TEXT_PARAMS, *OPTION_PARAMS.keys).to_h.symbolize_keys.compact_blank.merge(
      created_at: date_range('created'), last_activity_at: date_range('last_activity')
    ).compact
  end
end
