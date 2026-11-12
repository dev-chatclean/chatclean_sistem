# "Visão geral": the conversations of the last 7, 30 or 90 days next to the sales of the same days, in the viewer's time zone.
# The conversation filters narrow only the conversation numbers; the owner filter also narrows the sales numbers.
class Crm::OverviewReport
  include Crm::ReportPeriod

  CONVERSATION_COLUMNS = %i[team_id inbox_id assignee_id status created_at last_activity_at].freeze
  CHANNEL_KINDS = {
    'Channel::Whatsapp' => 'whatsapp', 'Channel::Instagram' => 'instagram', 'Channel::FacebookPage' => 'messenger',
    'Channel::WebWidget' => 'site', 'Channel::Email' => 'email', 'Channel::Telegram' => 'telegram', 'Channel::Line' => 'line',
    'Channel::Sms' => 'sms', 'Channel::TwilioSms' => 'sms', 'Channel::Api' => 'api', 'Channel::Tiktok' => 'tiktok',
    'Channel::TwitterProfile' => 'twitter'
  }.freeze

  pattr_initialize [:account!, :period!, :time_zone!, { filters: {} }]

  def build
    {
      kpis: kpis(current_range).merge(open_kpis),
      previous_kpis: kpis(previous_range),
      volume_timeline: volume_timeline(current_range),
      previous_volume_timeline: volume_timeline(previous_range),
      by_channel: channel_rows,
      pipeline: pipeline_json,
      agents: agent_rows
    }
  end

  private

  def conversations
    @conversations ||= begin
      scope = account.conversations.where(filters.slice(*CONVERSATION_COLUMNS))
      scope = scope.where(contact_id: filtered_contacts.select(:id)) if filters[:contact_type] || filters[:contact_label]
      scope = scope.where(id: unread_conversation_ids) if filters[:unread]
      scope
    end
  end

  def filtered_contacts
    contacts = account.contacts
    contacts = contacts.where(contact_type: filters[:contact_type]) if filters[:contact_type]
    contacts = contacts.tagged_with(filters[:contact_label], on: :labels) if filters[:contact_label]
    contacts
  end

  # Unread as the Chatwoot inbox counts it: a customer message after the agent last opened the conversation.
  def unread_conversation_ids
    seen_at = Conversation.arel_table[:agent_last_seen_at]
    Message.unscoped.incoming.where(account_id: account.id).joins(:conversation)
           .where(Message.arel_table[:created_at].gt(seen_at).or(seen_at.eq(nil))).select(:conversation_id)
  end

  def deals
    @deals ||= account.crm_deals.where(filters.slice(:assignee_id))
  end

  def won_in(range)
    deals.won.where(closed_at: range)
  end

  def kpis(range)
    created_deals = deals.where(created_at: range)
    created_count = created_deals.count
    {
      conversations: conversations.where(created_at: range).count,
      won_value: won_in(range).sum(:value).to_f, won_count: won_in(range).count,
      # Conversão "lead → ganho": of the deals created in the period, the share already won.
      conversion: (created_deals.won.count.to_f / created_count if created_count.positive?)
    }
  end

  # Em aberto: the conversations open now, whatever the period, and how many of them wait for a reply.
  def open_kpis
    open = conversations.open
    { open_count: open.count, waiting_count: open.where.not(waiting_since: nil).count }
  end

  def volume_timeline(range)
    conversations.where(created_at: range).group_by_day(:created_at, range: range, time_zone: time_zone)
                 .count.map { |date, count| { date: date.iso8601, count: count } }
  end

  # Por canal: every kind of channel the account has, with the conversations of the period.
  def channel_rows
    counts = conversations.where(created_at: current_range).group(:inbox_id).count
    rows = account.inboxes.includes(:channel).group_by { |inbox| channel_kind(inbox) }.map do |kind, inboxes|
      { key: kind, count: inboxes.sum { |inbox| counts.fetch(inbox.id, 0) } }
    end
    rows.sort_by { |row| -row[:count] }
  end

  def channel_kind(inbox)
    return 'whatsapp' if inbox.channel_type == 'Channel::TwilioSms' && inbox.channel.whatsapp?

    CHANNEL_KINDS.fetch(inbox.channel_type)
  end

  # Pipeline por etapa: the open deals per stage of the account's default pipeline.
  def pipeline_json
    pipeline = account.crm_pipelines.find_by(is_default: true)
    return unless pipeline

    stages = pipeline.stages.reject(&:closing?)
    open = deals.open.where(stage: stages).group(:stage_id)
    counts = open.count
    values = open.sum(:value)
    { name: pipeline.name, stages: stages.map { |stage| stage_row(stage, counts, values) } }
  end

  def stage_row(stage, counts, values)
    { id: stage.id, name: stage.name, color: stage.color, open_count: counts.fetch(stage.id, 0), open_value: values.fetch(stage.id, 0).to_f }
  end

  # Desempenho por atendente: the conversations of the period per assignee and the value each one won.
  def agent_rows
    counts = conversations.where(created_at: current_range).group(:assignee_id).count
    won_values = won_in(current_range).group(:assignee_id).sum(:value)
    account.users.where(id: counts.keys | won_values.keys).map do |user|
      { id: user.id, name: user.available_name, thumbnail: user.avatar_url }
        .merge(conversations: counts.fetch(user.id, 0), won_value: won_values.fetch(user.id, 0).to_f)
    end
  end
end
