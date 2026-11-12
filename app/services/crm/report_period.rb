# The days a CRM report covers: the last 7, 30 or 90 days in the viewer's time zone, and the same number of days just before.
module Crm::ReportPeriod
  private

  def now
    @now ||= Time.current.in_time_zone(time_zone)
  end

  def current_range
    @current_range ||= (now - (period - 1).days).beginning_of_day..now.end_of_day
  end

  def previous_range
    (current_range.begin - period.days)...current_range.begin
  end
end
