# Vendas & Pipeline, second part: where the leads came from, what was sold and to whom, and why deals were won or lost.
# The deal lists are capped; everything else is aggregated in SQL or from plucked columns.
class Crm::SalesReportBreakdowns
  DEALS_LIST_LIMIT = 100
  TOP_COMPANIES = 10
  NO_REASON = [nil, 'not_informed'].freeze

  pattr_initialize [:deals!, :range!, :pipeline]

  def build
    {
      by_origin: cohort_rows(created, :lead_origin),
      by_channel: channel_rows,
      origin_wins: won.group(:lead_origin).sum(:value).map { |origin, value| { key: origin, value: value.to_f } },
      by_product: product_rows,
      by_company: company_rows,
      won_reasons: reason_rows(won),
      lost_reasons: reason_rows(lost),
      won_deals: deal_rows(won),
      lost_deals: deal_rows(lost),
      where_lost: where_lost_rows
    }
  end

  private

  def won
    deals.won.where(closed_at: range)
  end

  def lost
    deals.lost.where(closed_at: range)
  end

  def created
    deals.where(created_at: range)
  end

  # Leads created in the period per origin or channel, and how many of them were won or lost.
  def cohort_rows(scope, column)
    counts = scope.group(column, :status).count
    values = scope.won.group(column).sum(:value)
    counts.keys.map(&:first).uniq.map do |key|
      {
        key: key, leads: counts.sum { |(group, _status), count| group == key ? count : 0 },
        won: counts.fetch([key, 'won'], 0), lost: counts.fetch([key, 'lost'], 0), value: values.fetch(key, 0).to_f
      }
    end
  end

  # The channel is the inbox of the conversation the deal came from.
  def channel_rows
    scope = Crm::Deal.where(id: created.select(:id)).left_joins(:conversation)
    rows = cohort_rows(scope, Conversation.arel_table[:inbox_id])
    names = Inbox.where(id: rows.pluck(:key).compact).pluck(:id, :name).to_h
    rows.map { |row| row.merge(name: names[row[:key]]) }
  end

  def product_rows
    items = Crm::DealProduct.where(deal_id: won.select(:id)).pluck(:product_id, :quantity, :unit_price)
    names = Crm::Product.where(id: items.map(&:first)).pluck(:id, :name).to_h
    rows = items.group_by(&:first).map do |product_id, group|
      { id: product_id, name: names[product_id], units: group.sum { |row| row[1] }, revenue: group.sum { |row| row[1] * row[2] }.to_f }
    end
    rows.sort_by { |row| -row[:revenue] }
  end

  # The companies that brought the most in the period, and what is still open with each one.
  def company_rows
    totals = company_totals
    ids = totals[:won_value].keys | created.where.not(company_id: nil).distinct.pluck(:company_id)
    rows = Company.where(id: ids).pluck(:id, :name).map do |id, name|
      { id: id, name: name }.merge(totals.transform_values { |values| values.fetch(id, 0) })
    end
    rows.sort_by { |row| [-row[:won_value], -row[:open_value]] }.first(TOP_COMPANIES)
  end

  def company_totals
    open = deals.open.where.not(company_id: nil).group(:company_id)
    {
      won_value: won.where.not(company_id: nil).group(:company_id).sum(:value).transform_values(&:to_f),
      open_value: open.sum(:value).transform_values(&:to_f), open_count: open.count
    }
  end

  def reason_rows(scope)
    with_reason = scope.where.not(close_reason: NO_REASON)
    values = with_reason.group(:close_reason).sum(:value)
    with_reason.group(:close_reason).count.map { |reason, count| { key: reason, count: count, value: values[reason].to_f } }
               .sort_by { |row| -row[:count] }
  end

  def deal_rows(scope)
    list = scope.order(closed_at: :desc).limit(DEALS_LIST_LIMIT).includes(:assignee, :contact, :company, deal_products: :product).to_a
    lost_stages = lost_stage_names(list.map(&:id))
    list.map { |deal| deal_row(deal).merge(lost_stage: lost_stages[deal.id]) }
  end

  def deal_row(deal)
    {
      id: deal.id, number: deal.number, name: deal.display_name, assignee: deal.assignee.available_name,
      products: deal.deal_products.map { |item| item.product.name }, value: deal.value.to_f,
      reason: deal.close_reason, note: deal.close_note, closed_at: deal.closed_at.to_i,
      cycle_seconds: (deal.closed_at - deal.created_at).round
    }
  end

  # The stage each deal was in when it was lost: the origin of its last "lost" event.
  def lost_stage_names(deal_ids)
    Crm::DealEvent.where(deal_id: deal_ids, event_type: 'lost').order(:created_at)
                  .joins(:from_stage).pluck(:deal_id, Crm::Stage.arel_table[:name]).to_h
  end

  # Onde o negócio se perde: losses of the period per stage of the pipeline the report shows.
  def where_lost_rows
    return [] unless pipeline

    stages = pipeline.stages.reject(&:closing?)
    lost_by_stage = Crm::DealEvent.where(deal_id: lost.select(:id), event_type: 'lost', from_stage_id: stages.map(&:id), created_at: range)
                                  .joins(:deal).pluck(:from_stage_id, Crm::Deal.arel_table[:value]).group_by(&:first)
    stages.map do |stage|
      rows = lost_by_stage.fetch(stage.id, [])
      { id: stage.id, name: stage.name, color: stage.color, lost: rows.size, value: rows.sum(&:last).to_f }
    end
  end
end
