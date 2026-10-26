# Horário da conta e feriados nos canais (US 19, CCV2-27), acrescentado ao Inbox do Chatwoot pelo
# initializer chatclean_hooks.
module Chatclean::InboxSchedule
  def self.prepended(base)
    # Canal novo nasce com o horário da conta, quando ela está em "por conta" (CA 19.3).
    base.after_create :follow_account_schedule
  end

  # No feriado, o canal com horário ligado fica fora do horário o dia todo, no fuso dele (CA 19.7).
  def out_of_office?
    super || (working_hours_enabled? && holiday_today.present?)
  end

  # Mensagem de ausência de agora: a do feriado (ou a padrão) no feriado, senão a do canal.
  def away_message
    holiday = holiday_today if working_hours_enabled?
    return out_of_office_message unless holiday

    holiday.message.presence || I18n.with_locale(account.locale) { I18n.t('chatclean.holidays.default_message') }
  end

  def holiday_today
    Chatclean::Holiday.find_by(account_id: account_id, date: Time.current.in_time_zone(timezone).to_date)
  end

  private

  def follow_account_schedule
    schedule = Chatclean::AccountSchedule.find_by(account_id: account_id)
    schedule.apply_to(self) if schedule&.per_account?
  end
end
