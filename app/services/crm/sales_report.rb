# "Vendas & Pipeline": the indicators and blocks of the sales report for the last 7, 30 or 90 days, in the viewer's time zone.
# Money and counts are SQL aggregates; durations and stale deals come from plucked columns, never from whole records.
# The stage blocks use the pipeline of the filter, or the account's default pipeline.
class Crm::SalesReport
  pattr_initialize [:account!, :period!, :time_zone!, { filters: {} }]

  def build
    {
      pipeline: pipeline && { id: pipeline.id, name: pipeline.name, stages: pipeline.stages.map { |stage| stage_json(stage) } },
      kpis: kpis(current_range).merge(open_kpis),
      previous_kpis: kpis(previous_range),
      wins_timeline: wins_timeline(current_range),
      previous_wins_timeline: wins_timeline(previous_range),
      stages: stage_rows,
      assignees: assignee_rows
    }
  end

  private

  def deals
    @deals ||= account.crm_deals.report_filtered(filters)
  end

  def now
    @now ||= Time.current.in_time_zone(time_zone)
  end

  def current_range
    @current_range ||= (now - (period - 1).days).beginning_of_day..now.end_of_day
  end

  def previous_range
    (current_range.begin - period.days)...current_range.begin
  end

  def pipeline
    return @pipeline if defined?(@pipeline)

    @pipeline = filters[:pipeline_id] ? account.crm_pipelines.find(filters[:pipeline_id]) : account.crm_pipelines.find_by(is_default: true)
  end

  def won_in(range)
    deals.won.where(closed_at: range)
  end

  def lost_in(range)
    deals.lost.where(closed_at: range)
  end

  def kpis(range)
    won_count = won_in(range).count
    lost_count = lost_in(range).count
    won_value = won_in(range).sum(:value).to_f
    closed = won_count + lost_count
    {
      won_value: won_value, won_count: won_count,
      lost_value: lost_in(range).sum(:value).to_f, lost_count: lost_count,
      conversion: (won_count.to_f / closed if closed.positive?),
      average_ticket: (won_value / won_count if won_count.positive?),
      close_seconds: average_duration(won_in(range)),
      loss_seconds: average_duration(lost_in(range))
    }
  end

  def average_duration(scope)
    durations = scope.pluck(:created_at, :closed_at).map { |created_at, closed_at| closed_at - created_at }
    (durations.sum / durations.size).round if durations.any?
  end

  # "Em aberto (pipeline)" and "N parados" are a picture of now, not of the period.
  def open_kpis
    open = deals.open
    { open_value: open.sum(:value).to_f, stale_count: open.pluck(:stage_id, :stage_entered_at).count { |stage_id, at| stale?(stage_id, at) } }
  end

  def stale_after_days
    @stale_after_days ||= Crm::Stage.where(account: account).pluck(:id, :stale_after_days).to_h
  end

  def stale?(stage_id, entered_at)
    days = stale_after_days[stage_id]
    days.present? && entered_at < days.days.ago
  end

  def wins_timeline(range)
    won_in(range).group_by_period(period == 90 ? :week : :day, :closed_at, range: range, time_zone: time_zone)
                 .sum(:value).map { |date, value| { date: date.iso8601, value: value.to_f } }
  end

  # Pipeline, Conversão entre etapas and Estagnação: one row per open stage, in the pipeline's order.
  def stage_rows
    return [] unless pipeline

    stages = pipeline.stages.reject(&:closing?)
    open = deals.open.where(stage: stages).pluck(:stage_id, :value, :stage_entered_at).group_by(&:first)
    reached = reached_stages
    stages.each_with_index.map do |stage, index|
      stage_json(stage).merge(open_stage_numbers(stage, open.fetch(stage.id, [])), conversion_numbers(reached, stage, stages[index + 1]))
    end
  end

  def open_stage_numbers(stage, rows)
    average = (rows.sum { |row| now - row[2] } / rows.size).round if rows.any?
    {
      open_count: rows.size, open_value: rows.sum { |row| row[1] }.to_f,
      stale_count: rows.count { |row| stale?(stage.id, row[2]) }, average_seconds: average
    }
  end

  def conversion_numbers(reached, stage, next_stage)
    stage_deals = reached.fetch(stage.id, Set.new)
    moved_on = (stage_deals & reached.fetch(next_stage.id, Set.new)).size if next_stage
    { reached: stage_deals.size, moved_on: moved_on }
  end

  # Deals created in the period and the stages each one reached; a skipped stage does not count.
  def reached_stages
    created = deals.where(pipeline: pipeline, created_at: current_range).select(:id)
    Crm::DealEvent.where(deal_id: created).where.not(to_stage_id: nil).distinct.pluck(:to_stage_id, :deal_id)
                  .group_by(&:first).transform_values { |pairs| pairs.to_set(&:last) }
  end

  # Por responsável and Colaboradores.
  def assignee_rows
    columns = assignee_columns
    ids = columns.values.flat_map(&:keys).uniq
    account.users.where(id: ids).map do |user|
      { id: user.id, name: user.available_name, thumbnail: user.avatar_url }
        .merge(columns.transform_values { |values| values.fetch(user.id, 0) })
    end
  end

  def assignee_columns
    won = won_in(current_range).group(:assignee_id)
    lost = lost_in(current_range).group(:assignee_id)
    {
      deals: deals.where(created_at: current_range).group(:assignee_id).count,
      won_count: won.count, won_value: won.sum(:value).transform_values(&:to_f),
      lost_count: lost.count, lost_value: lost.sum(:value).transform_values(&:to_f)
    }.merge(activity_columns)
  end

  # Activities count for the person they are assigned to, on the deals the filters keep.
  def activity_columns
    activities = Crm::DealActivity.where(deal_id: deals.select(:id)).group(:assignee_id)
    {
      activities_done: activities.where(completed_at: current_range).count,
      activities_overdue: activities.pending.where(due_at: ...Time.current).count
    }
  end

  def stage_json(stage)
    { id: stage.id, name: stage.name, color: stage.color, stage_type: stage.stage_type }
  end
end
