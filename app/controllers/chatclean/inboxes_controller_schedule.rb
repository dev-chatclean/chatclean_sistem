# Em "por conta", o horário dos canais vem da conta (US 19, CCV2-27): o canal não muda o próprio
# horário, para não se afastar do da conta.
module Chatclean::InboxesControllerSchedule
  SCHEDULE_PARAMS = %w[working_hours working_hours_enabled timezone out_of_office_message].freeze

  def self.prepended(base)
    base.before_action :keep_account_schedule, only: :update
  end

  private

  def keep_account_schedule
    return unless Chatclean::AccountSchedule.find_by(account_id: Current.account.id)&.per_account?
    return unless params.keys.intersect?(SCHEDULE_PARAMS)

    render_could_not_create_error(I18n.t('chatclean.schedule.errors.follows_account'))
  end
end
