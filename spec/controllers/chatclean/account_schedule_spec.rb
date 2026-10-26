require 'rails_helper'

RSpec.describe 'Account business hours and holidays', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:schedule_path) { "/api/v1/accounts/#{account.id}/working_schedule" }
  let(:holidays_path) { "/api/v1/accounts/#{account.id}/holidays" }
  let(:week) do
    (0..6).map do |day|
      if day.zero?
        { day_of_week: 0, closed_all_day: true, open_all_day: false }
      else
        { day_of_week: day, closed_all_day: false, open_all_day: false, open_hour: 8, open_minutes: 0, close_hour: 18, close_minutes: 0 }
      end
    end
  end

  def put_schedule(attributes, user = admin)
    put schedule_path, params: { working_schedule: attributes }, headers: user.create_new_auth_token, as: :json
  end

  describe 'business hours' do
    it 'copies the account hours to every inbox in per account mode, and to new inboxes' do
      put_schedule(mode: 'per_account', enabled: true, timezone: 'America/Sao_Paulo', out_of_office_message: 'Fora do horário', working_hours: week)

      expect(response).to have_http_status(:success)
      expect(inbox.reload).to have_attributes(working_hours_enabled: true, timezone: 'America/Sao_Paulo', out_of_office_message: 'Fora do horário')
      expect(inbox.working_hours.find_by(day_of_week: 1)).to have_attributes(open_hour: 8, close_hour: 18)
      expect(create(:inbox, account: account).working_hours.find_by(day_of_week: 3).close_hour).to eq(18)
    end

    it 'keeps the last account hours on each inbox when going back to per channel' do
      put_schedule(mode: 'per_account', enabled: true, timezone: 'America/Sao_Paulo', working_hours: week)
      put_schedule(mode: 'per_channel')

      expect(inbox.reload.working_hours.find_by(day_of_week: 1).close_hour).to eq(18)
    end

    it 'refuses an invalid timezone, a missing day, closing before opening and closed with open 24h' do
      bad_days = [
        week.first(6),
        week.each_with_index.map { |day, index| index == 1 ? day.merge(close_hour: 7) : day },
        week.each_with_index.map { |day, index| index.zero? ? day.merge(open_all_day: true) : day }
      ]

      put_schedule(timezone: 'Lua/Crateras')
      expect(response).to have_http_status(:unprocessable_entity)
      bad_days.each do |days|
        put_schedule(working_hours: days)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'lets everyone see the hours and only the administrator change them' do
      get schedule_path, headers: agent.create_new_auth_token, as: :json
      expect(response.parsed_body).to include('mode' => 'per_channel', 'timezone' => 'America/Sao_Paulo')

      put_schedule({ mode: 'per_account' }, agent)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'stops an inbox from changing its own hours while the account rules them' do
      put_schedule(mode: 'per_account', enabled: true, working_hours: week)

      patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", params: { working_hours_enabled: false },
                                                                  headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(inbox.reload.working_hours_enabled).to be(true)
    end
  end

  describe 'holidays' do
    it 'imports the national holidays of the year without duplicating or overwriting' do
      create(:chatclean_holiday, account: account, date: Date.new(2027, 12, 25), name: 'Natal da empresa')

      post "#{holidays_path}/import_national", params: { year: 2027 }, headers: admin.create_new_auth_token, as: :json
      post "#{holidays_path}/import_national", params: { year: 2027 }, headers: admin.create_new_auth_token, as: :json

      holidays = Chatclean::Holiday.where(account: account)
      expect(holidays.count).to eq(10)
      expect(holidays.find_by(date: Date.new(2027, 3, 26)).name).to eq('Good Friday')
      expect(holidays.find_by(date: Date.new(2027, 12, 25)).name).to eq('Natal da empresa')
    end

    it 'keeps one holiday per date and lists them by year' do
      create(:chatclean_holiday, account: account, date: Date.new(2027, 9, 8))
      create(:chatclean_holiday, account: account, date: Date.new(2028, 9, 8))

      post holidays_path, params: { holiday: { date: '2027-09-08', name: 'Outro' } }, headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      get holidays_path, params: { year: 2027 }, headers: agent.create_new_auth_token
      expect(response.parsed_body.pluck('date')).to eq(['2027-09-08'])
    end

    it 'does not let an agent change holidays' do
      post holidays_path, params: { holiday: { date: '2027-09-08', name: 'Aniversário da cidade' } },
                          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'on a holiday' do
    before do
      inbox.update!(working_hours_enabled: true, timezone: 'America/Sao_Paulo', out_of_office_message: 'Fora do horário')
      inbox.working_hours.each { |working_hour| working_hour.update!(open_all_day: true, closed_all_day: false) }
    end

    it 'keeps an inbox with hours out of office all day, with the holiday message or the default one' do
      holiday = create(:chatclean_holiday, account: account, date: Time.current.in_time_zone('America/Sao_Paulo').to_date)

      expect(inbox).to be_out_of_office
      expect(inbox.away_message).to eq(I18n.t('chatclean.holidays.default_message'))

      holiday.update!(message: 'Feliz aniversário da cidade!')
      expect(inbox.away_message).to eq('Feliz aniversário da cidade!')
    end

    it 'does not affect an inbox without business hours' do
      create(:chatclean_holiday, account: account, date: Time.current.in_time_zone('America/Sao_Paulo').to_date)
      inbox.update!(working_hours_enabled: false)

      expect(inbox).not_to be_out_of_office
      expect(inbox.away_message).to eq('Fora do horário')
    end

    it 'answers a new customer message with the holiday message' do
      create(:chatclean_holiday, account: account, date: Time.current.in_time_zone('America/Sao_Paulo').to_date, message: 'Hoje é feriado!')
      conversation = create(:conversation, account: account, inbox: inbox)
      message = create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)

      MessageTemplates::HookExecutionService.new(message: message).perform

      expect(conversation.messages.template.last&.content).to eq('Hoje é feriado!')
    end
  end
end
