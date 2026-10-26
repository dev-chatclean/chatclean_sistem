# Horário de atendimento da conta (US 19, CCV2-27). Em "por conta", o horário é copiado para todos
# os canais, que seguem usando a checagem e a mensagem de ausência do Chatwoot. Voltando para "por
# canal", cada canal parte do último horário da conta (CA 19.4).
class Chatclean::AccountSchedule < Chatclean::ApplicationRecord
  DAY_ATTRS = OutOfOffisable::OFFISABLE_ATTRS

  belongs_to :account

  enum :mode, { per_channel: 0, per_account: 1 }

  validates :timezone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validates :out_of_office_message, length: { maximum: Limits::OUT_OF_OFFICE_MESSAGE_MAX_LENGTH }
  validate :seven_valid_days

  after_save :apply_to_inboxes, if: :per_account?

  def self.for(account)
    find_or_initialize_by(account: account) do |schedule|
      schedule.working_hours = OutOfOffisable::DEFAULT_WORKING_HOURS.map { |day| day.stringify_keys.slice(*DAY_ATTRS) }
    end
  end

  def apply_to(inbox)
    inbox.update!(working_hours_enabled: enabled, timezone: timezone, out_of_office_message: out_of_office_message)
    inbox.update_working_hours(working_hours)
  end

  private

  def apply_to_inboxes
    account.inboxes.find_each { |inbox| apply_to(inbox) }
  end

  # Os sete dias, cada um "Fechado", "Aberto 24h" ou um intervalo com o fechamento depois da abertura.
  def seven_valid_days
    days = Array(working_hours)
    return errors.add(:working_hours, I18n.t('chatclean.schedule.errors.seven_days')) unless days.pluck('day_of_week').sort == (0..6).to_a

    days.each { |day| validate_day(day) }
  end

  def validate_day(day)
    return errors.add(:working_hours, I18n.t('chatclean.schedule.errors.closed_and_open')) if day['closed_all_day'] && day['open_all_day']
    return if day['closed_all_day'] || day['open_all_day']

    open, close = %w[open close].map { |edge| (day["#{edge}_hour"].to_i * 60) + day["#{edge}_minutes"].to_i }
    errors.add(:working_hours, I18n.t('chatclean.schedule.errors.close_before_open')) if close <= open
  end
end
